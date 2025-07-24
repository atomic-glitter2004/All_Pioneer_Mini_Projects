include("plot_graph.jl")
using Makie.Colors
using Random
using StatsBase
using Colors
using SimpleGraphs
using SimpleWeightedGraphs
using Graphs

const my_neighbors = Graphs.neighbors

function read_edges(filename)
    edges = []
    open(filename, "r") do file
        for line in eachline(file)
            if isempty(strip(line)) || startswith(strip(line), "#")
                continue
            end
            u, v = split(line)
            push!(edges, (parse(Int, u), parse(Int, v)))
        end
    end
    return edges
end

function build_graph(edges)
    if isempty(edges)
        error("Invalid imput")
    end
    nodes = unique(vcat([e[1] for e in edges], [e[2] for e in edges]))
    g = SimpleGraph(maximum(nodes))
    for (u, v) in edges
        add_edge!(g, u, v)
    end
    return g
end

function compute_modularity(g, label_dict)
    m = ne(g)
    Q = 0.0
    for i in 1:nv(g)
        for j in 1:nv(g)
            if i == j
                continue
            end
            if label_dict[i] == label_dict[j]
                Aij = has_edge(g, i, j) ? 1.0 : 0.0
                ki = degree(g, i)
                kj = degree(g, j)
                Q += (Aij - (ki * kj) / (2 * m))
            end
        end
    end
    return Q / (2 * m)
end

function label_propagation_modularity(g)
    labels = Dict(n => n for n in 1:nv(g))  
    label_changed = true

    while label_changed
        label_changed = false
        for u in shuffle(1:nv(g))
            original_label = labels[u]
            best_label = original_label
            best_score = compute_modularity(g, labels)

            neighbor_labels = Set(labels[v] for v in my_neighbors(g, u))
            for lbl in neighbor_labels
                labels[u] = lbl
                score = compute_modularity(g, labels)
                if score > best_score
                    best_score = score
                    best_label = lbl
                end
            end

            labels[u] = best_label
            if best_label != original_label
                label_changed = true
            end
        end
    end

    return labels
end

function main()
    edge_file = "graph03.txt"  

    edges = read_edges(edge_file)
    g = build_graph(edges)
    final_labels = label_propagation_modularity(g)
    println("Modularity Score: ", round(compute_modularity(g, final_labels), digits=3))

groups = Dict{Int, Vector{Int}}()
for (node, lbl) in final_labels
    push!(get!(groups, lbl, Int[]), node)
end

group_num = 1
for lbl in sort(collect(keys(groups)))
    nodes = sort(groups[lbl])
    println("Group $(group_num): ", join(nodes, ", "))
    group_num += 1
end

    palette_size = 16
    color_palette = Makie.distinguishable_colors(palette_size)

    unique_labels = unique(values(final_labels))
    sort!(unique_labels)
    label_to_color_index = Dict(unique_labels[i] => mod1(i, palette_size) for i in eachindex(unique_labels))
    node_color_indices = [label_to_color_index[final_labels[n]] for n in 1:nv(g)]
    node_colors = [color_palette[i] for i in node_color_indices]
    node_text_colors = [Colors.Lab(RGB(c)).l > 50 ? :black : :white for c in node_colors]

    interactive_plot_graph(g, node_colors, node_text_colors, node_color_indices, color_palette)
end

main()