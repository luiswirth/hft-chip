module trader
    import orderbook_pkg::*;
#(
    parameter int N = 8
)(
    input  logic           clk_i,
    input  logic           rst_ni,
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

    typedef enum logic [1:0] {
        IDLE   = 2'd0,
        TRADE1 = 2'd1,
        TRADE2 = 2'd2
    } state_t;

    state_t state_q, state_d;

    price_t ask_price_q,  ask_price_d;
    price_t bid_price_q,  bid_price_d;
    qty_t   arb_qty_q,    arb_qty_d;
    logic   ask_market_q, ask_market_d;
    logic   bid_market_q, bid_market_d;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q     <= IDLE;
            ask_price_q  <= '0;
            bid_price_q  <= '0;
            arb_qty_q   <= '0;
            ask_market_q <= '0;
            bid_market_q <= '0;
        end else begin
            state_q     <= state_d;
            ask_price_q  <= ask_price_d;
            bid_price_q  <= bid_price_d;
            arb_qty_q   <= arb_qty_d;
            ask_market_q <= ask_market_d;
            bid_market_q <= bid_market_d;
        end
    end

    always_comb begin
        state_d     = state_q;
        ask_price_d  = ask_price_q;
        bid_price_d  = bid_price_q;
        arb_qty_d   = arb_qty_q;
        ask_market_d = ask_market_q;
        bid_market_d = bid_market_q;

        // default
        valid_o  = '0;
        market_o = '0;
        side_o   = Bid;
        price_o  = '0;
        qty_o    = '0;

        case (state_q)

            IDLE: begin
                if (bid_prices0_i[0] > ask_prices1_i[0]) begin
                    ask_market_d = '0;
                    bid_market_d = '1;

                    ask_price_d  = bid_prices0_i[0];
                    bid_price_d  = ask_prices1_i[0];
                    arb_qty_d    = (bid_qtys0_i[0] < ask_qtys1_i[0]) ? bid_qtys0_i[0] : ask_qtys1_i[0];
                    
                    state_d      = TRADE1;
                end else if (bid_prices1_i[0] > ask_prices0_i[0]) begin
                    ask_market_d = '1;
                    bid_market_d = '0;

                    ask_price_d  = bid_prices1_i[0];
                    bid_price_d  = ask_prices0_i[0];
                    arb_qty_d    = (bid_qtys1_i[0] < ask_qtys0_i[0]) ? bid_qtys1_i[0] : ask_qtys0_i[0];

                    state_d      = TRADE1;
                end
            end

            TRADE1: begin
                valid_o  = '1;
                market_o = ask_market_q;
                side_o   = Ask;
                price_o  = ask_price_q;
                qty_o    = arb_qty_q;
                state_d  = TRADE2;
            end

            TRADE2: begin
                valid_o  = '1;
                market_o = bid_market_q;
                side_o   = Bid;
                price_o  = bid_price_q;
                qty_o    = arb_qty_q;
                state_d  = IDLE;
            end

            default: state_d = IDLE;

        endcase
    end

endmodule