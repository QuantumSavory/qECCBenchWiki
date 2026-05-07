module DBHelpers

using SQLite
using DBInterface

using ..Helpers: logrange, instancenameof, skipredundantprefix, typenameof

const CONN = Ref{Union{Nothing, SQLite.DB}}(nothing)
const DB_PATH = Ref("codes/")
const DB_FILENAME = Ref("results.sqlite")

function init_db!(path=DB_PATH[]; filename="results.sqlite") # path should be a directory, not a file
    file_path = joinpath(path, filename) # path/filename
    if CONN[] !== nothing && path == DB_PATH[] && filename == DB_FILENAME[]
        return CONN[] # already initialized with the same database
    end
    if CONN[] !== nothing
        DBInterface.close!(CONN[]) # close existing connection if path changes
        CONN[] = nothing
    end
    mkpath(path)
    CONN[] = DBInterface.connect(SQLite.DB, file_path)
    DB_PATH[] = path
    DB_FILENAME[] = filename
    SQLite.busy_timeout(CONN[], 100)
    collect(DBInterface.execute(
        CONN[],
        """CREATE TABLE IF NOT EXISTS results
        (code TEXT, decoder TEXT, setup TEXT, error REAL, nsamples INTEGER, logx REAL, logz REAL,
            PRIMARY KEY (code, decoder, setup, error))"""
    ))
    collect(DBInterface.execute(CONN[], "PRAGMA journal_mode=WAL"))
    return CONN[]
end

db() = isnothing(CONN[]) ? init_db!() : CONN[]

function dbrow(code, decoder, setup, e)
    coden = skipredundantprefix(instancenameof(code))
    decodern = skipredundantprefix(decoder)
    setupn = skipredundantprefix(setup)
    res = DBInterface.execute(
        db(),
        "SELECT * FROM results WHERE code=? AND decoder=? AND setup=? AND error=?",
        (coden, decodern, setupn, e))
    try
        if isempty(res)
            return nothing
        end
        row = first(res)
        return (
            code=row.code,
            decoder=row.decoder,
            setup=row.setup,
            error=row.error,
            nsamples=row.nsamples,
            logx=row.logx,
            logz=row.logz,
        )
    finally
        DBInterface.close!(res)
    end
end

function dbnarray(codes, decoders, setups, errors)
    nᶜ = length(codes)
    nᵈ = length(decoders)
    nˢ = length(setups)
    nᵉ = length(errors)
    narray = zeros(nᵉ, 2, nᶜ, nᵈ, nˢ)
    for iᶜ in 1:nᶜ
        for iᵈ in 1:nᵈ
            for iˢ in 1:nˢ
                for iᵉ in 1:nᵉ
                    row = dbrow(codes[iᶜ], decoders[iᵈ], setups[iˢ], errors[iᵉ])
                    narray[iᵉ, :, iᶜ, iᵈ, iˢ] .= isnothing(row) ? NaN : (row.logx, row.logz)
                end
            end
        end
    end
    return narray
end

function dbrow!(code, decoder, setup, e, n, le)
    dbrow!(code, decoder, setup, e, n, le, le)
end

function dbrow!(code, decoder, setup, e, n, lx, lz)
    coden = skipredundantprefix(instancenameof(code))
    decodern = skipredundantprefix(decoder)
    setupn = skipredundantprefix(setup)
    while true # retry on sqlite busy
        try
            conn = db()
            collect(DBInterface.execute(
                conn,
                """
                INSERT INTO results (code, decoder, setup, error, nsamples, logx, logz)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(code, decoder, setup, error) DO UPDATE SET
                    nsamples = results.nsamples + excluded.nsamples,
                    logx = (
                        results.logx * results.nsamples +
                        excluded.logx * excluded.nsamples
                    ) / (results.nsamples + excluded.nsamples),
                    logz = (
                        results.logz * results.nsamples +
                        excluded.logz * excluded.nsamples
                    ) / (results.nsamples + excluded.nsamples)
                """,
                (coden, decodern, setupn, e, n, lx, lz),
            ))
            row = dbrow(code, decoder, setup, e)
            return row.code, row.decoder, row.setup, row.error, row.nsamples, row.logx, row.logz
        catch e
            if e == SQLite.SQLiteException("database is locked")
                @debug "Database locked, retrying..."
            else
                rethrow(e)
            end
        end
    end
end

end
