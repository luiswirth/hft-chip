module trader
    import orderbook_pkg::*;
#(
    parameter int N = 8
)(
    input logic clk_i,
    input logic rst_ni,

    input  price_t [N-1:0] bid_prices0_i,
    input  qty_t   [N-1:0] bid_qtys0_i,
    input  price_t [N-1:0] ask_prices0_i,
    input  qty_t   [N-1:0] ask_qtys0_i,

    input  price_t [N-1:0] bid_prices1_i,
    input  qty_t   [N-1:0] bid_qtys1_i,
    input  price_t [N-1:0] ask_prices1_i,
    input  qty_t   [N-1:0] ask_qtys1_i,

    output logic           valid_o,
    output logic           market_o,
    output side_t          side_o,
    output price_t         price_o,
    output qty_t           qty_o
);

    qty_t arb_qty;

    always_comb begin
        valid_o = '0;
        side_o  = Bid;
        price_o = '0;
        qty_o   = '0;
        market_o = '0;

        if (bid_prices0_i[0] > ask_prices1_i[0]) begin
            arb_qty = (bid_qtys0_i[0] < ask_qtys1_i[0]) ? bid_qtys0_i[0] : ask_qtys1_i[0];

            // trade 0
            valid_o = '1;
            market_o = '0;
            side_o  = Ask;
            price_o = bid_prices0_i[0];
            qty_o = arb_qty;

            // trade 1
            // valid_o = '1;
            // market_o = '1;
            // side_o  = Bid;
            // price_o = ask_prices1_i[0];
            // qty_o = arb_qty;
        end else if (bid_prices1_i[0] > ask_prices0_i[0]) begin
            arb_qty = (bid_qtys1_i[0] < ask_qtys0_i[0]) ? bid_qtys1_i[0] : ask_qtys0_i[0];

            // trade 0
            valid_o = '1;
            market_o = '1;
            side_o  = Ask;
            price_o = bid_prices1_i[0];
            qty_o = arb_qty;

            // trade 1
            // valid_o = '1;
            // market_o = '0;
            // side_o  = Bid;
            // price_o = ask_prices0_i[0];
            // qty_o = arb_qty;
        end

    end


        





endmodule
