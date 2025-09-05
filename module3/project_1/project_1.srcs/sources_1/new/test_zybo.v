`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Shivadharshan
// 
// Create Date: 05.09.2025 21:00:47
// Design Name: 
// Module Name: test_zybo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module zybo_pin_test (
    // Clock and Reset
    input wire clk,           // 125MHz system clock
    input wire reset,         // Reset button (btn[0])
    
    // Switches
    input wire [3:0] sw,      // 4 switches
    
    // Buttons  
    input wire [3:1] btn,     // 3 additional buttons (btn[1] to btn[3])
    
    // LEDs
    output reg [3:0] led,     // 4 regular LEDs
    
    // RGB LED 6
//    output reg led6_r,        // Red component
//    output reg led6_g,        // Green component  
//    output reg led6_b,        // Blue component
    
    // VGA outputs (for testing VGA pins)
    output reg [3:0] vga_r,   // VGA Red
    output reg [3:0] vga_g,   // VGA Green
    output reg [3:0] vga_b,   // VGA Blue
    output reg vga_hsync,     // VGA Horizontal Sync
    output reg vga_vsync      // VGA Vertical Sync
);

    // Clock divider for visible counting and blinking
    reg [26:0] counter;       // Main counter for clock division
    reg [3:0] display_counter; // Counter displayed on LEDs
    reg [2:0] rgb_counter;    // Counter for RGB LED cycling
    
    // Clock enable signals
    wire clk_1hz;             // 1Hz clock for counter increment
    wire clk_2hz;             // 2Hz clock for blinking
    wire clk_fast;            // Fast clock for RGB cycling
    
    // Generate different clock enables from main counter
    assign clk_1hz = counter[26];      // ~1Hz (125MHz / 2^27 ≈ 0.93Hz)
    assign clk_2hz = counter[25];      // ~2Hz (125MHz / 2^26 ≈ 1.86Hz)  
    assign clk_fast = counter[23];     // ~15Hz for RGB cycling
    
    // Previous clock states for edge detection
    reg clk_1hz_prev, clk_2hz_prev, clk_fast_prev;
    reg [3:1] btn_prev;               // Previous button states
    
    // Main counter increment
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 27'b0;
        end else begin
            counter <= counter + 1;
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_1hz_prev <= 1'b0;
            clk_2hz_prev <= 1'b0;
            clk_fast_prev <= 1'b0;
            btn_prev <= 3'b0;
        end else begin
            clk_1hz_prev <= clk_1hz;
            clk_2hz_prev <= clk_2hz;
            clk_fast_prev <= clk_fast;
            btn_prev <= btn;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            display_counter <= 4'b0000;
        end else begin
            // Increment on 1Hz rising edge
            if (clk_1hz && !clk_1hz_prev) begin
                display_counter <= display_counter + 1;
            end
            // Also increment on any button press (rising edge)
            else if ((btn[1] && !btn_prev[1]) || 
                     (btn[2] && !btn_prev[2]) || 
                     (btn[3] && !btn_prev[3])) begin
                display_counter <= display_counter + 1;
            end
        end
    end
    
    // LED display logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            led <= 4'b0000;
        end else begin
            // Display counter value combined with switch positions
            // This allows testing both counter functionality and switch inputs
            led <= display_counter ^ sw; // XOR creates interesting patterns
        end
    end
    
    reg [2:0] pixel_clk_div;
    wire pixel_clk;
    
    // VGA timing counters
    reg [9:0] h_count;  // Horizontal counter (0-799)
    reg [9:0] v_count;  // Vertical counter (0-524)
    
    // VGA timing parameters
    localparam H_DISPLAY    = 640;
    localparam H_FRONT      = 16;
    localparam H_SYNC       = 96;
    localparam H_BACK       = 48;
    localparam H_TOTAL      = H_DISPLAY + H_FRONT + H_SYNC + H_BACK; // 800
    
    localparam V_DISPLAY    = 480;
    localparam V_FRONT      = 10;
    localparam V_SYNC       = 2;
    localparam V_BACK       = 33;
    localparam V_TOTAL      = V_DISPLAY + V_FRONT + V_SYNC + V_BACK; // 525
    
    // Generate 25MHz pixel clock from 125MHz system clock
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pixel_clk_div <= 3'b0;
        end else begin
            if (pixel_clk_div == 3'd4) begin
                pixel_clk_div <= 3'b0;
            end else begin
                pixel_clk_div <= pixel_clk_div + 1;
            end
        end
    end
    
    assign pixel_clk = (pixel_clk_div == 3'd4);
    
    // VGA timing generation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            h_count <= 10'b0;
            v_count <= 10'b0;
        end else if (pixel_clk) begin
            // Horizontal counter
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'b0;
                // Vertical counter
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 10'b0;
                end else begin
                    v_count <= v_count + 1;
                end
            end else begin
                h_count <= h_count + 1;
            end
        end
    end
    
    // Generate sync signals
    wire h_sync_pulse = (h_count >= (H_DISPLAY + H_FRONT)) && 
                        (h_count < (H_DISPLAY + H_FRONT + H_SYNC));
    wire v_sync_pulse = (v_count >= (V_DISPLAY + V_FRONT)) && 
                        (v_count < (V_DISPLAY + V_FRONT + V_SYNC));
    
    // Active video area
    wire h_active = (h_count < H_DISPLAY);
    wire v_active = (v_count < V_DISPLAY);
    wire video_active = h_active && v_active;
    
    // VGA output generation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            vga_r <= 4'b0000;
            vga_g <= 4'b0000; 
            vga_b <= 4'b0000;
            vga_hsync <= 1'b1;  // VGA sync is normally high, active low
            vga_vsync <= 1'b1;
        end else begin
            // Sync signals (active low)
            vga_hsync <= ~h_sync_pulse;
            vga_vsync <= ~v_sync_pulse;
            
            if (video_active) begin
                // Create test pattern in active video area
                // Divide screen into regions for testing
                
                // Top quarter: Red with counter pattern
                if (v_count < 120) begin
                    vga_r <= display_counter;
                    vga_g <= 4'b0000;
                    vga_b <= 4'b0000;
                end
                // Second quarter: Green with switch pattern
                else if (v_count < 240) begin
                    vga_r <= 4'b0000;
                    vga_g <= sw;
                    vga_b <= 4'b0000;
                end
                // Third quarter: Blue with button pattern
                else if (v_count < 360) begin
                    vga_r <= 4'b0000;
                    vga_g <= 4'b0000;
                    vga_b <= {btn[3], btn[2], btn[1], 1'b0};
                end
                // Bottom quarter: White/colorful pattern
                else begin
                    // Create a simple gradient/pattern
                    vga_r <= h_count[3:0];
                    vga_g <= v_count[3:0];
                    vga_b <= h_count[7:4] ^ v_count[7:4];
                end
            end else begin
                // Blanking period - all outputs to zero
                vga_r <= 4'b0000;
                vga_g <= 4'b0000;
                vga_b <= 4'b0000;
            end
        end
    end
    
    
endmodule
