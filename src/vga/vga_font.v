// Five columns and seven rows per glyph, most significant bit at top left.
module vga_font (input [7:0] character, input [2:0] x, y, output pixel);
    reg [34:0] glyph;
    always @(*) begin
        case (character)
            "0": glyph = 35'h3A33AE62E;
            "1": glyph = 35'h11842108E;
            "2": glyph = 35'h3A211111F;
            "3": glyph = 35'h78213063E;
            "4": glyph = 35'h08CA97C42;
            "5": glyph = 35'h7E1E0862E;
            "6": glyph = 35'h1910F462E;
            "7": glyph = 35'h7C2222108;
            "8": glyph = 35'h3A317462E;
            "9": glyph = 35'h3A317844C;
            "A": glyph = 35'h3A31FC631;
            "B": glyph = 35'h7A31F463E;
            "C": glyph = 35'h3A308422E;
            "D": glyph = 35'h7A318C63E;
            "E": glyph = 35'h7E10F421F;
            "F": glyph = 35'h7E10F4210;
            "G": glyph = 35'h3A30BC62F;
            "H": glyph = 35'h4631FC631;
            "I": glyph = 35'h38842108E;
            "J": glyph = 35'h1C4214A4C;
            "K": glyph = 35'h4654C5251;
            "L": glyph = 35'h42108421F;
            "M": glyph = 35'h4775AC631;
            "N": glyph = 35'h4739ACE71;
            "O": glyph = 35'h3A318C62E;
            "P": glyph = 35'h7A31F4210;
            "Q": glyph = 35'h3A318D64D;
            "R": glyph = 35'h7A31F5251;
            "S": glyph = 35'h3E107043E;
            "T": glyph = 35'h7C8421084;
            "U": glyph = 35'h46318C62E;
            "V": glyph = 35'h46318C544;
            "W": glyph = 35'h4631AD6AA;
            "X": glyph = 35'h462A22A31;
            "Y": glyph = 35'h462A21084;
            "Z": glyph = 35'h7C222221F;
            "+": glyph = 35'h0084F9080;
            "-": glyph = 35'h0000F8000;
            "*": glyph = 35'h02AEFBAA0;
            "=": glyph = 35'h001F07C00;
            "?": glyph = 35'h3A2221004;
            "$": glyph = 35'h11F4717C4;
            default: glyph = 35'd0;
        endcase
    end
    assign pixel = (x < 3'd5 && y < 3'd7) ? glyph[34 - 5 * y - x] : 1'b0;
endmodule
