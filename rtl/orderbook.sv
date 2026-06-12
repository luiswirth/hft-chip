module orderbook
    import orderbook_pkg::*;
#(
    parameter int N = 8
)(
    input logic clk_i,
    input logic rst_ni,

    input logic valid_i,

    input op_t op_i,
    input side_t side_i,
    input price_t price_i,
    input qty_t qty_i,

    output price_t [N-1:0] bid_prices_o,
    output qty_t   [N-1:0] bid_qtys_o,
    output price_t [N-1:0] ask_prices_o,
    output qty_t   [N-1:0] ask_qtys_o,

    output logic error_o
);

    typedef price_t[N-1:0] prices_t;
    typedef qty_t[N-1:0] qtys_t;

    prices_t bid_prices_d, bid_prices_q;
    qtys_t bid_qtys_d, bid_qtys_q;

    prices_t ask_prices_d, ask_prices_q;
    qtys_t ask_qtys_d, ask_qtys_q;

    logic error_d, error_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            error_q <= 1'b0;

            bid_prices_q <= '{default: DEFAULT_BID};
            bid_qtys_q <= 0;
            ask_prices_q <= '{default: DEFAULT_ASK};
            ask_qtys_q <= 0;
        end else begin
            error_q <= error_d;
        
            bid_prices_q <= bid_prices_d;
            bid_qtys_q <= bid_qtys_d;
            ask_prices_q <= ask_prices_d;
            ask_qtys_q <= ask_qtys_d;
        end
    end

    function automatic logic [$clog2(N)-1:0] first(
        input logic [N-1:0] array
    );
        first = 0;
        for (int i = N-1; i >= 0; i--) begin
            if (array[i])
                first = i[$clog2(N)-1:0];
        end
    endfunction

    always_comb begin
        prices_t prices_q;
        prices_t prices_d;
        qtys_t qtys_q;
        qtys_t qtys_d;
        logic[N-1:0] compares;
        logic[N-1:0] equals;
        logic any_eq;
        logic[$clog2(N)-1:0] eq_idx;
        logic[$clog2(N)-1:0] cmp_idx;
        logic pre_error;
        logic onehot;
        
        bid_prices_d = bid_prices_q;
        bid_qtys_d = bid_qtys_q;
        ask_prices_d = ask_prices_q;
        ask_qtys_d = ask_qtys_q;

        error_d = error_q;

        if (valid_i && !error_q) begin
            prices_q = (side_i == Bid) ? bid_prices_q : ask_prices_q;
            qtys_q = (side_i == Bid) ? bid_qtys_q : ask_qtys_q;

            prices_d = prices_q;
            qtys_d = qtys_q;

            for (int i = 0; i < N; i++) begin 
                equals[i] = prices_q[i] == price_i;
                compares[i] = (side_i == Bid) ? (price_i > prices_q[i]) : (price_i < prices_q[i]);
            end

            any_eq = |equals;
            eq_idx = first(equals);


            onehot = (equals & (equals - 1)) == 0;
        pre_error = (qty_i == 0) || (any_eq && !onehot);

            if (pre_error) begin
                error_d = 1'b1;
            end else begin
                unique case (op_i)
                    Insert: if (any_eq) begin
                        // overflow check
                        if (qty_i > '1 - qtys_q[eq_idx]) begin
                            error_d = 1'b1;
                        end else begin
                            qtys_d[eq_idx] = qtys_q[eq_idx] + qty_i;
                        end
                    end else if (|compares) begin
                        cmp_idx = first(compares); // only call first if we have at least one 
                        for (int i = 1; i < N; i++) begin
                            prices_d[i] = (i > cmp_idx) ? prices_q[i-1] : prices_q[i];
                            qtys_d[i]   = (i > cmp_idx) ? qtys_q[i-1]   : qtys_q[i];
                        end
                        prices_d[cmp_idx] = price_i;
                        qtys_d[cmp_idx]   = qty_i;
                    end else begin
                        error_d = 1'b1;
                    end
                    Remove: if (any_eq && qtys_q[eq_idx] >= qty_i) begin
                        if(qtys_q[eq_idx] == qty_i) begin
                            for (int i = 0; i < N-1; i++) begin
                                prices_d[i] = (i < eq_idx) ? prices_q[i] : prices_q[i+1];
                                qtys_d[i]   = (i < eq_idx) ? qtys_q[i]   : qtys_q[i+1];
                            end
                            prices_d[N-1] = (side_i == Bid) ? DEFAULT_BID : DEFAULT_ASK;
                            qtys_d[N-1] = 0; 
                        end else begin
                            qtys_d[eq_idx] = qtys_q[eq_idx] - qty_i;
                        end
                    end else begin
                        error_d = 1'b1;
                    end
                    default: begin
                        error_d = 1'b1;
                    end
                endcase

                unique case (side_i)
                    Bid: begin
                        bid_prices_d = prices_d;
                        bid_qtys_d = qtys_d;
                    end
                    Ask: begin
                        ask_prices_d = prices_d;
                        ask_qtys_d = qtys_d;
                    end
                    default: begin
                        error_d = 1'b1;
                    end
                endcase
            end
        end
    end

    assign bid_prices_o = bid_prices_q;
    assign bid_qtys_o   = bid_qtys_q;
    assign ask_prices_o = ask_prices_q;
    assign ask_qtys_o   = ask_qtys_q;

    assign error_o = error_q;

endmodule
