`timescale 1ns / 1ps

module matmul_tb;
    integer file, i, file2;

    reg [15:0] binary_data;  // assuming 8-bit binary data
    reg clk = 0, rst = 1;
    reg  [15:0][15:0] a;
    reg  [ 3:0][15:0] b;
    wire [ 3:0][15:0] out;

    matmul f1 (
        .clk(clk),
        .rst(rst),
        .a  (a),
        .b  (b),
        .x  (out)
    );
    always #1 clk = ~clk;

    initial begin
        $dumpfile("matmul_tb.vcd");
        $dumpvars(0, matmul_tb);

        // Open the file in read mode
        file  = $fopen("binarydata.txt", "r");
        file2 = $fopen("binarydata2.txt", "w");
        if (file == 0) begin
            $display("Failed to open file");
            $finish;
        end

        for (i = 0; i < 16; i = i + 1) begin
            if (!$feof(file)) begin
                if ($fscanf(file, "%b\n", binary_data)) begin
                    $display("Read binary data: %b", binary_data);
                    a[i] = binary_data;
                end
            end
        end
        $display("Value of a %b", a[15]);
        while (!$feof(
            file
        )) begin
            for (i = 0; i < 4; i = i + 1) begin
                if (!$feof(file)) begin
                    if ($fscanf(file, "%b\n", binary_data)) begin
                        $display("Read binary data: %b", binary_data);
                        b[i] = binary_data;
                    end
                end
            end
            #10 $display("Value of out %b", out);
            for (i = 0; i < 4; i = i + 1) begin
                $fwrite(file2, "%b\n", out[i]);
            end
        end
        // Close the file
        $fclose(file);

        $finish;
    end
endmodule
