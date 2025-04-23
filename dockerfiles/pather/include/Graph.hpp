#pragma once

#include <vector>
#include <unordered_set>
#include <functional>

#include <msgpack.hpp>

// this is required to support set deserialization
namespace msgpack {
MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS) {
namespace adaptor {

template <typename T>
struct convert<std::unordered_set<T>> {
    msgpack::object const& operator()(msgpack::object const& o, std::unordered_set<T>& v) const {
        if (o.type != msgpack::type::ARRAY) throw msgpack::type_error();
        v.clear();
        for (uint32_t i = 0; i < o.via.array.size; ++i) {
            v.insert(o.via.array.ptr[i].as<T>());
        }
        return o;
    }
};

}
}
}


struct Edge {
    int from;
    int to;
    double length;
    bool pointLike;
    int speed;
    int crashes;

    Edge() : from(-1), to(-1), length(0), pointLike(true), crashes(0), speed(0) {};

    MSGPACK_DEFINE(from, to, length, pointLike, speed, crashes);
};

struct Node {
    double x;
    double y;
    std::unordered_map< int, std::unordered_set<int> > restrict_paths;
    std::unordered_map<int, int> enforce_paths;
    std::vector<int> children;

    std::vector<int> getChildren(int parent_node) const;

    Node() : x(0), y(0) {};

    MSGPACK_DEFINE(x, y, restrict_paths, enforce_paths, children);
};

struct Graph {
    int node_count, edge_count;
    std::vector<Node> nodes;
    std::vector<Edge> edges;

    Graph() : node_count(0), edge_count(0) {};

    MSGPACK_DEFINE(node_count, edge_count, nodes, edges);
};

std::pair<std::vector<int>, double> Dijkstra(const Graph& graph, int start, int goal, std::function<double(int)> cost_fn);

std::pair<std::vector<int>, double> Astar(const Graph& graph, int start, int goal, std::function<double(int)> cost_fn, std::function<double(int, int)> heuristic_fn);
