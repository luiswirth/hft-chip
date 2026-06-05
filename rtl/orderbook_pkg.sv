package orderbook_pkg;
    typedef logic [9:0] price_t;
    typedef logic [7:0] qty_t;
    typedef enum logic {Insert, Remove} op_t;
    typedef enum logic {Bid, Ask} side_t;
    localparam price_t DEFAULT_BID = '0; // min value
    localparam price_t DEFAULT_ASK = '1; // max value
endpackage

