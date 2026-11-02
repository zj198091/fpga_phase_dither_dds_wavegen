module fir_config(
    input               clk,
    input               rst,
    input       [11:0]  data_in,
    input       [1:0]   mode_sel,
    output reg  [11:0]  data_out
);

// 17级移位寄存器链
reg [11:0] shift_reg [16:0];
integer i;

// 三组12位有符号系数
wire signed [11:0] coe [2:0][16:0];

// 低通系数
assign coe[0][0]  = 12'sd0;
assign coe[0][1]  = 12'sd9;
assign coe[0][2]  = 12'sd37;
assign coe[0][3]  = 12'sd78;
assign coe[0][4]  = 12'sd127;
assign coe[0][5]  = 12'sd177;
assign coe[0][6]  = 12'sd219;
assign coe[0][7]  = 12'sd247;
assign coe[0][8]  = 12'sd257;
assign coe[0][9]  = 12'sd247;
assign coe[0][10] = 12'sd219;
assign coe[0][11] = 12'sd177;
assign coe[0][12] = 12'sd127;
assign coe[0][13] = 12'sd78;
assign coe[0][14] = 12'sd37;
assign coe[0][15] = 12'sd9;
assign coe[0][16] = 12'sd0;

// 带通系数
assign coe[1][0]  = 12'sd0;
assign coe[1][1]  = 12'sd7;
assign coe[1][2]  = 12'sd30;
assign coe[1][3]  = 12'sd72;
assign coe[1][4]  = 12'sd126;
assign coe[1][5]  = 12'sd186;
assign coe[1][6]  = 12'sd241;
assign coe[1][7]  = 12'sd278;
assign coe[1][8]  = 12'sd292;
assign coe[1][9]  = 12'sd278;
assign coe[1][10] = 12'sd241;
assign coe[1][11] = 12'sd186;
assign coe[1][12] = 12'sd126;
assign coe[1][13] = 12'sd72;
assign coe[1][14] = 12'sd30;
assign coe[1][15] = 12'sd7;
assign coe[1][16] = 12'sd0;

// 高通系数
assign coe[2][0]  = 12'sd0;
assign coe[2][1]  = -12'sd3;
assign coe[2][2]  = -12'sd14;
assign coe[2][3]  = -12'sd33;
assign coe[2][4]  = -12'sd56;
assign coe[2][5]  = -12'sd80;
assign coe[2][6]  = -12'sd102;
assign coe[2][7]  = -12'sd117;
assign coe[2][8]  = 12'sd1924;
assign coe[2][9]  = -12'sd117;
assign coe[2][10] = -12'sd102;
assign coe[2][11] = -12'sd80;
assign coe[2][12] = -12'sd56;
assign coe[2][13] = -12'sd33;
assign coe[2][14] = -12'sd14;
assign coe[2][15] = -12'sd3;
assign coe[2][16] = 12'sd0;

// ==================== 流水线寄存器定义 ====================
// 第1级：17个乘法结果单独打拍（乘法是时序延迟最大的部分）
reg signed [23:0] mult_res [16:0];
// 第2级：分段求和结果
reg signed [27:0] sum_p1;
reg signed [27:0] sum_p2;
reg signed [27:0] sum_p3;
// 第3级：最终累加结果
reg signed [27:0] sum_reg;

// ==================== 17级移位寄存器 ====================
always @(posedge clk or posedge rst) begin
    if(rst) begin
        for(i = 0; i < 17; i = i + 1)
            shift_reg[i] <= 12'd0;
    end
    else begin
        shift_reg[0] <= data_in;
        for(i = 1; i < 17; i = i + 1)
            shift_reg[i] <= shift_reg[i-1];
    end
end

// ==================== 第1级流水线：完成所有乘法运算 ====================
// 把乘法单独拆成一级，这是时序优化的核心
always @(posedge clk or posedge rst) begin
    if(rst) begin
        for(i = 0; i < 17; i = i + 1)
            mult_res[i] <= 24'sd0;
    end
    else begin
        for(i = 0; i < 17; i = i + 1)
            mult_res[i] <= $signed(shift_reg[i] - 12'd2048) * coe[mode_sel][i];
    end
end

// ==================== 第2级流水线：分段加法 ====================
always @(posedge clk or posedge rst) begin
    if(rst) begin
        sum_p1 <= 28'sd0;
        sum_p2 <= 28'sd0;
        sum_p3 <= 28'sd0;
    end
    else begin
        sum_p1 <= mult_res[0] + mult_res[1] + mult_res[2] + mult_res[3] + mult_res[4] + mult_res[5];
        sum_p2 <= mult_res[6] + mult_res[7] + mult_res[8] + mult_res[9] + mult_res[10] + mult_res[11];
        sum_p3 <= mult_res[12] + mult_res[13] + mult_res[14] + mult_res[15] + mult_res[16];
    end
end

// ==================== 第3级流水线：最终求和 + 输出截位 ====================
always @(posedge clk or posedge rst) begin
    if(rst) begin
        sum_reg <= 28'sd0;
        data_out <= 12'd2048;
    end
    else begin
        sum_reg <= sum_p1 + sum_p2 + sum_p3;
        data_out <= sum_reg[22:11] + 12'd2048;
    end
end

endmodule