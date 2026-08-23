module CodeArtifacts

using MAT: matwrite
using QuantumClifford: stab_to_gf2
using QuantumClifford.ECC: parity_checks, iscss, parity_matrix_x, parity_matrix_z
using QECCore: parity_matrix
using SparseArrays

using ..Helpers: instancenameof, typenameof

const ARTIFACT_VERSION = "1"
const ARTIFACT_ROOT = "artifacts"
const MATRIX_MARKET_FORMAT = "Matrix Market coordinate integer general"
const FULL_MATRIX_FILE = "parity_matrix.mtx"
const X_MATRIX_FILE = "parity_matrix_x.mtx"
const Z_MATRIX_FILE = "parity_matrix_z.mtx"
const MAT_FILE = "matrices.mat"
const PARITY_CHECKS_FILE = "parity_checks.txt"
const MANIFEST_FILE = "manifest.toml"

binary_matrix(matrix) = matrix .!= 0
binary_sparse(matrix) = sparse(binary_matrix(matrix))

function full_parity_matrix(code)
    try
        return parity_matrix(code)
    catch err
        err isa MethodError && err.f === parity_matrix || rethrow()
    end

    if iscss(code) === true
        hx = binary_matrix(parity_matrix_x(code))
        hz = binary_matrix(parity_matrix_z(code))
        return [
            hx falses(size(hx, 1), size(hz, 2))
            falses(size(hz, 1), size(hx, 2)) hz
        ]
    end

    return stab_to_gf2(parity_checks(code))
end

function artifact_dir(codetypename, instance_name)
    return joinpath("codes", string(codetypename), ARTIFACT_ROOT, instance_name)
end

function remove_known_artifacts(dir)
    for filename in (
        FULL_MATRIX_FILE,
        X_MATRIX_FILE,
        Z_MATRIX_FILE,
        MAT_FILE,
        PARITY_CHECKS_FILE,
        MANIFEST_FILE,
    )
        rm(joinpath(dir, filename); force=true)
    end
end

function write_matrix_market(path, matrix, description)
    sparse_matrix = binary_sparse(matrix)
    rows, cols = size(sparse_matrix)
    row_indices, col_indices, _ = findnz(sparse_matrix)

    open(path, "w") do io
        println(io, "%%MatrixMarket matrix coordinate integer general")
        println(io, "% qECCBenchWiki parity-check matrix artifact")
        println(io, "% $(description)")
        println(io, "% Entries are binary over GF(2); all stored values are 1.")
        println(io, rows, " ", cols, " ", length(row_indices))

        for (row, col) in zip(row_indices, col_indices)
            println(io, row, " ", col, " 1")
        end
    end

    return sparse_matrix
end

function toml_string(value)
    escaped = replace(
        string(value),
        "\\" => "\\\\",
        "\"" => "\\\"",
        "\n" => "\\n",
        "\r" => "\\r",
        "\t" => "\\t",
    )
    return "\"$(escaped)\""
end

toml_value(value::AbstractString) = toml_string(value)
toml_value(value::Bool) = value ? "true" : "false"
toml_value(value::Integer) = string(value)

function write_toml_pair(io, key, value)
    println(io, key, " = ", toml_value(value))
end

function write_toml_table(io, name, fields)
    println(io)
    println(io, "[", name, "]")
    for (key, value) in pairs(fields)
        write_toml_pair(io, string(key), value)
    end
end

function matrix_manifest(filename, matrix, description)
    sparse_matrix = binary_sparse(matrix)
    return (;
        filename,
        format=MATRIX_MARKET_FORMAT,
        rows=size(sparse_matrix, 1),
        cols=size(sparse_matrix, 2),
        nnz=nnz(sparse_matrix),
        description,
    )
end

function write_manifest(path; codetypename, instance_name, code_is_css, full_matrix, x_matrix=nothing, z_matrix=nothing)
    open(path, "w") do io
        write_toml_pair(io, "artifact_version", ARTIFACT_VERSION)
        write_toml_pair(io, "code_family", string(codetypename))
        write_toml_pair(io, "instance_name", instance_name)
        write_toml_pair(io, "is_css", code_is_css)
        write_toml_pair(io, "field", "GF(2)")
        write_toml_pair(io, "full_matrix_column_order", "X_1..X_n followed by Z_1..Z_n")

        write_toml_table(io, "files.parity_matrix", matrix_manifest(
            FULL_MATRIX_FILE,
            full_matrix,
            "Full stabilizer parity-check matrix in (X|Z) column order.",
        ))

        if !isnothing(x_matrix)
            write_toml_table(io, "files.parity_matrix_x", matrix_manifest(
                X_MATRIX_FILE,
                x_matrix,
                "CSS X-check matrix Hx.",
            ))
        end

        if !isnothing(z_matrix)
            write_toml_table(io, "files.parity_matrix_z", matrix_manifest(
                Z_MATRIX_FILE,
                z_matrix,
                "CSS Z-check matrix Hz.",
            ))
        end

        println(io)
        println(io, "[files.mat_bundle]")
        write_toml_pair(io, "filename", MAT_FILE)
        write_toml_pair(io, "description", "MATLAB/Julia bundle containing sparse matrices and metadata.")

        println(io)
        println(io, "[files.parity_checks]")
        write_toml_pair(io, "filename", PARITY_CHECKS_FILE)
        write_toml_pair(io, "description", "Human-readable stabilizer generators from QuantumClifford.parity_checks.")
    end
end

function write_mat_bundle(path; codetypename, instance_name, code_is_css, full_matrix, x_matrix=nothing, z_matrix=nothing)
    data = Dict{String,Any}(
        "artifact_version" => ARTIFACT_VERSION,
        "code_family" => string(codetypename),
        "instance_name" => instance_name,
        "is_css" => Int8(code_is_css),
        "parity_matrix" => binary_sparse(full_matrix),
        "full_matrix_column_order" => "X_1..X_n followed by Z_1..Z_n",
    )

    if !isnothing(x_matrix)
        data["parity_matrix_x"] = binary_sparse(x_matrix)
    end

    if !isnothing(z_matrix)
        data["parity_matrix_z"] = binary_sparse(z_matrix)
    end

    matwrite(path, data)
end

function write_parity_checks(path; codetypename, instance_name, code)
    open(path, "w") do io
        println(io, "qECCBenchWiki parity-check generators")
        println(io, "code_family: ", codetypename)
        println(io, "instance_name: ", instance_name)
        println(io, "source: QuantumClifford.ECC.parity_checks")
        println(io)
        println(io, parity_checks(code))
    end
end

function prep_code_artifacts(code, codetypename)
    instance_name = instancenameof(code)
    dir = artifact_dir(codetypename, instance_name)
    mkpath(dir)
    remove_known_artifacts(dir)

    code_is_css = iscss(code) === true
    full_matrix = full_parity_matrix(code)
    x_matrix = code_is_css ? parity_matrix_x(code) : nothing
    z_matrix = code_is_css ? parity_matrix_z(code) : nothing

    write_matrix_market(
        joinpath(dir, FULL_MATRIX_FILE),
        full_matrix,
        "Full stabilizer parity-check matrix in (X|Z) column order.",
    )

    if code_is_css
        write_matrix_market(joinpath(dir, X_MATRIX_FILE), x_matrix, "CSS X-check matrix Hx.")
        write_matrix_market(joinpath(dir, Z_MATRIX_FILE), z_matrix, "CSS Z-check matrix Hz.")
    end

    write_mat_bundle(
        joinpath(dir, MAT_FILE);
        codetypename,
        instance_name,
        code_is_css,
        full_matrix,
        x_matrix,
        z_matrix,
    )
    write_parity_checks(joinpath(dir, PARITY_CHECKS_FILE); codetypename, instance_name, code)
    write_manifest(
        joinpath(dir, MANIFEST_FILE);
        codetypename,
        instance_name,
        code_is_css,
        full_matrix,
        x_matrix,
        z_matrix,
    )

    return dir
end

function prep_artifacts(code_metadata)
    for (codetype, metadata) in code_metadata
        codetypename = typenameof(codetype)
        @info "Generating artifacts for $(codetypename) ..."

        for instance_args in metadata[:family]
            code = codetype(instance_args...)
            prep_code_artifacts(code, codetypename)
        end
    end
end

end
