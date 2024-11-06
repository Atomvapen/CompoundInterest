const std = @import("std");
const print = std.debug.print;

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const msg = std.fmt.allocPrint(gpa_allocator.allocator(), "Fatal: " ++ format ++ "\n", args) catch std.process.exit(1);
    defer gpa_allocator.allocator().free(msg);
    std.io.getStdErr().writeAll(msg) catch std.process.exit(1);
    std.process.exit(1);
}

pub fn main() !void {
    const in = std.io.getStdIn();
    var buf = std.io.bufferedReader(in.reader());

    var r = buf.reader();
    var msg_buf: [4096]u8 = undefined;
    var msg: ?[]u8 = undefined;
    var result: compoundInterest = compoundInterest{ .initialInvestment = 0, .interestRate = 0, .timePeriod = 0, .monthlyContribution = 0 };

    inline for (&[_][]const u8{ "Startkapital", "Yield", "Contributions", "Years" }) |name| {
        std.debug.print(name ++ ": ", .{});
        msg = try r.readUntilDelimiterOrEof(&msg_buf, '\n');

        if (msg) |m| {
            const trimmed = std.mem.trim(u8, m, " \r\n");
            if (trimmed.len == 0) {
                fatal("No input provided for {s}", .{name});
            }
            // Validate that the string only contains digits
            for (trimmed) |char| {
                if (char < '0' or char > '9') {
                    fatal("Invalid input: '{s}' - must contain only numbers", .{trimmed});
                }
            }
        } else {
            fatal("No input provided for {s}", .{name});
        }

        const value: i64 = if (msg) |m|
            try std.fmt.parseInt(i64, std.mem.trim(u8, m, " \r\n"), 10)
        else
            0;

        if (std.mem.eql(u8, name, "Startkapital")) {
            result.initialInvestment = value;
        } else if (std.mem.eql(u8, name, "Yield")) {
            result.interestRate = value;
        } else if (std.mem.eql(u8, name, "Contributions")) {
            result.monthlyContribution = value;
        } else if (std.mem.eql(u8, name, "Years")) {
            result.timePeriod = value;
        }
    }
    result.calculate();
}

pub const compoundInterest = struct {
    timePeriod: i64 = 0,
    initialInvestment: i64 = 0,
    interestRate: i64 = 0,
    monthlyContribution: i64 = 0,

    pub fn calculate(interestProfile: compoundInterest) void {
        var totalCapital: i64 = interestProfile.initialInvestment;
        var year: i64 = interestProfile.timePeriod - 1;
        var totalContributions: i64 = 0;
        var totalYield: i64 = 0;

        // Print header
        print("\n{s: <6} {s: >15} {s: >20} {s: >15}\n", .{ "Year", "Capital", "Contributions", "Yield" });
        print("{s:-<60}\n", .{""}); // Separator line

        while (year >= 0) : (year -= 1) {
            totalCapital = @divFloor((totalCapital * (interestProfile.interestRate + 100)), 100) + interestProfile.monthlyContribution * 12;
            totalContributions += interestProfile.monthlyContribution * 12;
            totalYield = totalCapital - totalContributions - interestProfile.initialInvestment;

            // Print table row
            print("{d: >4} {d: >15} {d: >20} {d: >15}\n", .{
                interestProfile.timePeriod - year,
                totalCapital,
                totalContributions,
                totalYield,
            });
        }
    }
};
