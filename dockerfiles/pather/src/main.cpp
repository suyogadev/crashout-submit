#include "GraphHelper.hpp"

#include <iostream>
#include <csignal>
#include <atomic>

#include "mongoose.h"

static std::atomic<bool> s_interrupted{false};
static void signal_handler(int sig) {
    s_interrupted = true;
}

static void fn(struct mg_connection *c, int ev, void *ev_data) {
    if (ev == MG_EV_HTTP_MSG) {
        struct mg_http_message *hm = (struct mg_http_message *) ev_data;

        if (mg_match(hm->uri, mg_str("/"), NULL) && mg_match(hm->method, mg_str("POST"), NULL)) {
            try {
                std::string body(hm->body.buf, hm->body.len);
                nlohmann::json input = nlohmann::json::parse(body);

                auto* helper = static_cast<GraphHelper*>(c->fn_data);

                nlohmann::json output = helper->calculatePath(input);

                std::string response = output.dump();
                mg_http_reply(c, 200, "Content-Type: application/json\r\n", "%s", response.c_str());
            } catch (std::exception& e) {
                mg_http_reply(c, 400, "Content-Type: application/json\r\n",
                    "{\"success\":false,\"error\":\"%s\"}", e.what());
            }
        } else {
            mg_http_reply(c, 404, "", "Not found\n");
        }
    }
}

int main() {
    std::cout << "[pather] parsing msgpack data" << std::endl;
    GraphHelper helper("/data/path.msgpack");

    std::cout << "[pather] beginning server startup" << std::endl;

    // handle ctrl+c to exit early more gracefully
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    struct mg_mgr mgr;
    mg_mgr_init(&mgr);

    // unfortunately i hardcoded this
    // potential future improvement: add cmd line args
    struct mg_connection* conn = mg_http_listen(&mgr, "http://0.0.0.0:10143", fn, &helper);
    if (conn == nullptr) {
        std::cerr << "[pather] failed to bind port" << std::endl;
        return 1;
    }

    std::cout << "[pather] listening on http://0.0.0.0:10143" << std::endl;

    while (!s_interrupted) mg_mgr_poll(&mgr, 1000);
    mg_mgr_free(&mgr);
    return 0;
}
