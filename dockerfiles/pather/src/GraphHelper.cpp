#include "GraphHelper.hpp"

#include <fstream>
#include <chrono>
#include <memory>
#include <cmath>

inline double deg2rad(double deg) {
    return deg * M_PI / 180.0;
}

inline double haversine(double lat1, double lon1, double lat2, double lon2) {
    static constexpr double R = 3959.0;  // radius of earth in miles
    double dlat = deg2rad(lat2 - lat1);
    double dlon = deg2rad(lon2 - lon1);
    double a = std::sin(dlat/2) * std::sin(dlat/2) +
               std::cos(deg2rad(lat1)) * std::cos(deg2rad(lat2)) *
               std::sin(dlon/2) * std::sin(dlon/2);
    double c = 2 * std::atan2(std::sqrt(a), std::sqrt(1-a));
    return R * c;
}

GraphHelper::GraphHelper(const std::string& filename) {
    std::vector<char> buffer = read_file(filename);
    msgpack::object_handle oh = msgpack::unpack(buffer.data(), buffer.size());
    graph = oh.get().as<Graph>();

    nodeCloud.nodes = &graph.nodes;
    kdTree = std::make_unique<KDTree>(2, nodeCloud, nanoflann::KDTreeSingleIndexAdaptorParams(10));
    kdTree->buildIndex();
}

nlohmann::json GraphHelper::calculatePath(const nlohmann::json& j) {
    using clock = std::chrono::high_resolution_clock;

    nlohmann::json result;
    auto t0 = clock::now();

    try {  // if parsing fails then return generic error
        auto start_pt = j.at("start_point");
        auto end_pt = j.at("end_point");
        double sx = start_pt.at(0), sy = start_pt.at(1);
        double ex = end_pt.at(0), ey = end_pt.at(1);

        int algorithm = j.value("algorithm", 0);
        int cost = j.value("cost", 0);

        std::function<double(int)> cost_fn = [this](int idx) {
            Edge& edge = graph.edges[idx];
            if (edge.pointLike) return 0;
            return edge.crashes;
        };
        std::function<double(int, int)> heuristic = [this](int idx1, int idx2) {
            return 0;
        };

        switch (cost) {
            case 1:
                cost_fn = [this](int idx) {
                    Edge& edge = graph.edges[idx];
                    if (edge.pointLike) return 0.0;
                    return edge.length / edge.speed;
                };
                heuristic = [this](int idx1, int idx2) {
                    Node& start = graph.nodes[idx1];
                    Node& end = graph.nodes[idx2];
                    return haversine(start.y, start.x, end.y, end.x) / 70;
                };
                break;
            case 2:
                cost_fn = [this](int idx) {
                    Edge& edge = graph.edges[idx];
                    if (edge.pointLike) return 0.0;
                    return 1000000.0 - edge.crashes;
                };
                heuristic = [this](int idx1, int idx2) {
                    return 0;
                };
                break;
        }

        int start_idx = find_nearest_node(sx, sy);
        int end_idx = find_nearest_node(ex, ey);
        std::vector<int> path;

        switch (algorithm) {
            case 1:
                path = Astar(graph, start_idx, end_idx, cost_fn, heuristic).first;
                break;
            default:
                path = Dijkstra(graph, start_idx, end_idx, cost_fn).first;
        }

        bool success = !path.empty();

        std::vector<std::pair<double,double>> coords = getCoords(path);

        result["geom"] = {
            {"type", "LineString"},
            {"coordinates", coords}
        };
        result["success"] = success;

    } catch (const std::exception& e) {
        result["success"] = false;
        result["geom"] = {
            {"type", "LineString"},
            {"coordinates", nlohmann::json::array()}
        };
    }

    auto t1 = clock::now();
    result["time"] = std::chrono::duration_cast<std::chrono::microseconds>(t1 - t0).count();

    return result;
}

std::vector<char> GraphHelper::read_file(const std::string& filename) {
    std::ifstream ifs(filename, std::ios::binary | std::ios::ate);
    if (!ifs) throw std::runtime_error("Cannot open file: " + filename);
    std::streamsize size = ifs.tellg();
    ifs.seekg(0, std::ios::beg);

    std::vector<char> buffer(size);
    if (!ifs.read(buffer.data(), size))
        throw std::runtime_error("Error reading file: " + filename);
    return buffer;
}

int GraphHelper::find_nearest_node(double x, double y) const {
    double query_pt[2] = {x, y};
    size_t ret_index;
    double out_dist_sqr;
    nanoflann::KNNResultSet<double> resultSet(1);
    resultSet.init(&ret_index, &out_dist_sqr);
    kdTree->findNeighbors(resultSet, query_pt, nanoflann::SearchParams(10));
    return (int)ret_index;
}

std::vector<std::pair<double, double>> GraphHelper::getCoords(std::vector<int>& nodeIndices) {
    std::vector<std::pair<double, double>> coords;
    std::transform(nodeIndices.begin(), nodeIndices.end(), std::back_inserter(coords),
        [this](int idx) {
            return std::pair<double, double>{graph.nodes[idx].x, graph.nodes[idx].y};
        });
    return coords;
}
