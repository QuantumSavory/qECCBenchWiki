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
    DBInterface.execute(
        CONN[],
        """CREATE TABLE IF NOT EXISTS results
        (code TEXT, decoder TEXT, setup TEXT, error REAL, nsamples INTEGER, logx REAL, logz REAL,
            PRIMARY KEY (code, decoder, setup, error))"""
    )
    DBInterface.execute(CONN[], "PRAGMA journal_mode=WAL")
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
    isempty(res) ? nothing : first(res)
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
            newrow = DBInterface.transaction(conn) do
                old = dbrow(code, decoder, setup, e)
                newn, newlx, newlz = if isnothing(old)
                    n, lx, lz
                else
                    newn = n + old.nsamples
                    newn, (lx * n + old.logx * old.nsamples) / newn, (lz * n + old.logz * old.nsamples) / newn
                end
                newrow = coden, decodern, setupn, e, newn, newlx, newlz
                DBInterface.execute(
                    conn,
                    "REPLACE INTO results (code, decoder, setup, error, nsamples, logx, logz) VALUES (?, ?, ?, ?, ?, ?, ?)",
                    newrow
                )
                newrow
            end
            return newrow
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
