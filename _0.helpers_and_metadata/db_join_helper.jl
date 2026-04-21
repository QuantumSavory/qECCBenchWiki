module DBJoinHelper

using DataFrames
using SQLite
using DBInterface

export join_results

"""
    join_results(dir; output_path="codes/results.sqlite")

Merge all `.sqlite` files directly under `dir` (no subdirectories) into
`output_path`. Rows with identical `(code, decoder, setup, error)` are aggregated
by summing `nsamples` and taking a weighted average of `logx` and `logz`.

If the output file exists, it is overwritten.

Returns the output path.
"""
function join_results(dir; output_path="codes/results.sqlite")
    files = filter(f -> isfile(f) && endswith(lowercase(f), ".sqlite"), readdir(dir; join=true))

    isdir(dirname(output_path)) || mkdir(dirname(output_path))
    if isfile(output_path)
        @warn "Output file $output_path already exists and will be overwritten."
        rm(output_path)
    end

    combined = DataFrame(
        code=String[],
        decoder=String[],
        setup=String[],
        error=Float64[],
        nsamples=Int64[],
        logx=Float64[],
        logz=Float64[],
    )

    for f in files
        abf = abspath(f)
        println("Reading results from $abf...")
        indb = DBInterface.connect(SQLite.DB, abf)
        try
            part = DataFrame(DBInterface.execute(
                indb,
                "SELECT code, decoder, setup, error, nsamples, logx, logz FROM results",
            ))
            append!(combined, part; cols=:setequal, promote=true)
        finally
            DBInterface.close!(indb)
        end
    end

    merged = aggregate_results(combined)

    outdb = init_results_db(output_path)

    try
        DBInterface.transaction(outdb) do
            stmt = SQLite.Stmt(
                outdb,
                "INSERT INTO results (code, decoder, setup, error, nsamples, logx, logz) VALUES (?, ?, ?, ?, ?, ?, ?)",
            )
            try
                for row in eachrow(merged)
                    DBInterface.execute(stmt, (row.code, row.decoder, row.setup, row.error, row.nsamples, row.logx, row.logz))
                end
            finally
                DBInterface.close!(stmt)
            end
        end
    finally
        DBInterface.close!(outdb)
    end

    return output_path
end

function aggregate_results(df::DataFrame)
    isempty(df) && return df
    weighted = copy(df)
    weighted.logxw = weighted.logx .* weighted.nsamples
    weighted.logzw = weighted.logz .* weighted.nsamples
    grouped = combine(
        groupby(weighted, [:code, :decoder, :setup, :error]),
        :nsamples => sum => :nsamples,
        :logxw => sum => :logxw,
        :logzw => sum => :logzw,
    )
    grouped.logx = grouped.logxw ./ grouped.nsamples
    grouped.logz = grouped.logzw ./ grouped.nsamples
    return select(grouped, :code, :decoder, :setup, :error, :nsamples, :logx, :logz)
end

function init_results_db(output_path)
    outdb = DBInterface.connect(SQLite.DB, output_path)
    SQLite.busy_timeout(outdb, 5_000)
    collect(DBInterface.execute(
        outdb,
        """CREATE TABLE IF NOT EXISTS results
        (code TEXT, decoder TEXT, setup TEXT, error REAL, nsamples INTEGER, logx REAL, logz REAL,
            PRIMARY KEY (code, decoder, setup, error))"""
    ))
    collect(DBInterface.execute(outdb, "PRAGMA journal_mode=WAL"))
    return outdb
end

end