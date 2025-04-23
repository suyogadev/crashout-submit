#include "Graph.hpp"

#include <queue>
#include <limits>
#include <tuple>

std::vector<int> Node::getChildren(int parent_node) const {
    if (parent_node == -1) return children;

    auto it = enforce_paths.find(parent_node);
    if (it != enforce_paths.end()) {
        return { it->second };
    }

    auto restrict_it = restrict_paths.find(parent_node);
    if (restrict_it != restrict_paths.end()) {
        std::vector<int> output;
        auto& restrict_set = restrict_it->second;
        for (int child : children) {
            if (restrict_set.find(child) == restrict_set.end()) {
                output.push_back(child);
            }
        }
        return output;
    }

    return children;
}

// cost_fn takes in edge id
std::pair<std::vector<int>, double> Dijkstra(const Graph& graph, int start, int goal, std::function<double(int)> cost_fn) {
    using State = std::tuple<double, int, int, std::vector<int>>; // cost, node, prev_edge, path
    std::priority_queue<State, std::vector<State>, std::greater<>> q;
    std::vector<bool> visited(graph.node_count, false);

    q.push({0.0, start, -1, {}});

    while (!q.empty()) {
        auto [cost, node, prev_edge, path] = q.top();
        q.pop();
        if (visited[node]) continue;
        visited[node] = true;
        path.push_back(node);
        if (node == goal) return {path, cost};

        for (auto& edge_id : graph.nodes[node].getChildren(prev_edge)) {
            int neighbor = graph.edges[edge_id].to;
            double next_cost = cost_fn(edge_id);
            q.push({cost + next_cost, neighbor, edge_id, path});
        }
    }
    return {{}, std::numeric_limits<double>::infinity()};
}

// heuristic_fn takes in two node ids
std::pair<std::vector<int>, double> Astar(const Graph& graph, int start, int goal, std::function<double(int)> cost_fn, std::function<double(int, int)> heuristic_fn)
{
    using State = std::tuple<double, double, int, int, std::vector<int>>; // f_score, g_score, node, prev_edge, path
    std::priority_queue<State, std::vector<State>, std::greater<>> q;
    std::vector<bool> visited(graph.node_count, false);

    q.push({0.0, 0.0, start, -1, {}});

    while (!q.empty()) {
        auto [f, g, node, prev_edge, path] = q.top();
        q.pop();
        if (visited[node]) continue;
        visited[node] = true;
        path.push_back(node);
        if (node == goal) return {path, g};

        for (auto& edge_id : graph.nodes[node].getChildren(prev_edge)) {
            int neighbor = graph.edges[edge_id].to;
            double next_g = g + cost_fn(edge_id);
            double h = heuristic_fn(neighbor, goal);
            q.push({next_g + h, next_g, neighbor, edge_id, path});
        }
    }

    return {{}, std::numeric_limits<double>::infinity()};
}
