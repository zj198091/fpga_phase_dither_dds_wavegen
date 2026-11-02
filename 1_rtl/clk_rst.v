module clk_rst(
    input       sys_clk,
    input       sys_rst_n,
    output      clk_100m,
    output      clk_50m,
    output      clk_25m,
    output      sys_rst
);

wire locked;

clk_wiz_0 u_clk_wiz(
    .clk_in1(sys_clk),
    .reset(~sys_rst_n),
    .clk_out1(clk_100m),
    .clk_out2(clk_50m),
    .clk_out3(clk_25m),
    .locked(locked)
);

// 暂时不使用 locked 做复位，避免工具保守优化
assign sys_rst = 1'b0;

endmodule