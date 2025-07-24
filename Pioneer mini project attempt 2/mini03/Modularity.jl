using SimpleGraphs, SimpleWeightedGraphs

function read_weighted_edges(filename)
    edges = []
    weights = []
    open(filename, "r") do file
        for line in eachline(file)
            if isempty(strip(line)) || startswith(strip(line), "#")
                continue
            end
            parts = split(line)
            if length(parts) == 3
                u, v, w = parts
                push!(edges, (parse(Int, u), parse(Int, v)))
                push!(weights, parse(Float64, w))
            end
        end
    end
    return edges, weights
end

function read_groupings(filename)
    labels = Dict{Int, Int}()
    open(filename, "r") do file
        for line in eachline(file)
            if isempty(strip(line)) || startswith(strip(line), "#")
                continue
            end
            node, label = split(line)
            labels[parse(Int, node)] = parse(Int, label)
        end
    end
    return labels
end

function build_weighted_graph(edges, weights)
    if isempty(edges)
        error("No edges found. Check your input file.")
    end
    nodes = unique(vcat([e[1] for e in edges], [e[2] for e in edges]))
    g = SimpleWeightedGraph(maximum(nodes))
    for ((u, v), w) in zip(edges, weights)
        add_edge!(g, u, v, w)
    end
    return g
end

function compute_modularity_weighted(g, label_dict)
    m = sum(Graphs.weights(g)) / 2 
    Q = 0.0

    for i in 1:nv(g)
        for j in 1:nv(g)
            if i == j
                continue
            end
            if label_dict[i] == label_dict[j]
                Aij = Graphs.weights(g)[i, j]
                ki = sum(Graphs.weights(g)[i, n] for n in Graphs.neighbors(g, i))
                kj = sum(Graphs.weights(g)[j, n] for n in Graphs.neighbors(g, j))
                Q += (Aij - (ki * kj) / (2 * m))
            end
        end
    end

    return Q / (2 * m)
end

function main()
    edge_file = "graph01.txt"
    label_file = "label01.txt"

    edges, edge_weight = read_weighted_edges(edge_file)
    labels = read_groupings(label_file)
    g = build_weighted_graph(edges, edge_weight)

    Q = compute_modularity_weighted(g, labels)
    println("Modularity score: ", round(Q, digits=3))
end

main()