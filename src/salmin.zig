const std = @import("std");

const print = std.debug.print;
const assert = std.debug.assert;

// From: https://www.xe.com/symbols/
// Extraction:
// ```js
//  var [x, ...xs] = document.querySelectorAll("li.sc-d7407440-8.jHTviH")
//  data = xs.map(e => e.childNodes)
//      .map(c => [`${c[2].innerHTML}`, `${c[3].innerHTML}`, `${c[1].childNodes[0].text}`])
//      .reduce((acc, v) => { acc[v[0]] = v; return acc; }, {}))
//  data.map(d => `    .{ .currency_code = "${d[0]}", .country_and_currency = "${d[2]}", .symbols = "${d[1]}" },`)
//      .reduce((agg, v) => agg + "\n" + v, "")
// ```

const MAX_PATH_LENGTH = 1024 * 8;
const APP_NAME = "salmin";
const CONFIG_FILE = "salmin.conf";

const Currency = struct {
    currency_code: []const u8,
    country_and_currency: []const u8,
    symbols: []const u8,
};

const Conf = struct {
    currency_code: [3]u8 = .{ 'U', 'S', 'D' },
    salary_base: f64 = 60_000.0,
    salary_top: f64 = 100_000.0,
};

pub fn main() !void {
    var args_buffer: [MAX_PATH_LENGTH]u8 = undefined;
    var args_fba = std.heap.FixedBufferAllocator.init(args_buffer[0..]);
    const args = try std.process.argsAlloc(args_fba.allocator());

    if (args.len < 2) {
        print(
            \\ ERROR: Usage `salmin <number-of-meeting-participants> [OPTIONS]`
            \\     OPTIONS are specified as pairs, such as `--flag value`.
            \\
        , .{});
        return;
    }

    var dir_path_buffer: [MAX_PATH_LENGTH]u8 = undefined;
    var dir_fba = std.heap.FixedBufferAllocator.init(dir_path_buffer[0..]);

    const dir: ?[]const u8 = std.fs.getAppDataDir(dir_fba.allocator(), APP_NAME) catch |e| switch (e) {
        error.AppDataDirUnavailable => blk: {
            break :blk null;
        },
        error.OutOfMemory => {
            print("ERROR: Unable to reserve memory for the application data directory path. Exiting.\n", .{});
            return;
        },
    };

    var conf: Conf = .{};
    if (dir) |d| blk: {
        const appData = std.fs.openDirAbsolute(d, .{}) catch |e| switch (e) {
            error.FileNotFound => {
                warn_continue_with_defaults();
                break :blk;
            },
            else => return e,
        };
        const configFile = appData.openFile(CONFIG_FILE, .{}) catch |e| switch (e) {
            error.FileNotFound => {
                warn_continue_with_defaults();
                break :blk;
            },
            else => return e,
        };
        var reader = configFile.reader();

        var json_buffer: [MAX_PATH_LENGTH]u8 = undefined;
        const size = try reader.readAll(json_buffer[0..]);

        var parser_buffer: [MAX_PATH_LENGTH]u8 = undefined;
        var parser_fba = std.heap.FixedBufferAllocator.init(parser_buffer[0..]);
        const parsed = try std.json.parseFromSlice(Conf, parser_fba.allocator(), json_buffer[0..size], .{});
        defer parsed.deinit();

        conf = parsed.value;
        print("Loaded saved defaults.\n", .{});
    } else {
        warn_continue_with_defaults();
    }

    try salmin(conf, 5);
}

// Assuming 250 working days per year and 8 hour work days.
const salaried_minutes_per_year: f64 = 250.0 * 8.0 * 60.0;

fn salmin(conf: Conf, participants: u32) !void {
    var timer = try std.time.Timer.start();

    var found = false;
    var currency: Currency = undefined;
    for (currency_codes) |cc| {
        if (std.mem.eql(u8, conf.currency_code[0..3], cc.currency_code[0..3])) {
            currency = cc;
            found = true;
        }
    }

    if (!found) {
        print("ERROR: Unrecognized currency code '{s}'. Exiting.\n", .{conf.currency_code});
        return error.UnknownCurrency;
    }

    const combined_annual_salary = ((conf.salary_base + conf.salary_top) / 2) * @as(f64, @floatFromInt(participants));
    const combined_minutely_salary = (combined_annual_salary / salaried_minutes_per_year);

    while (true) {
        std.time.sleep(1 * std.time.ns_per_s);

        const time_elapsed_minutes = @as(f64, @floatFromInt(timer.read())) / std.time.ns_per_min;
        const cost = time_elapsed_minutes * combined_minutely_salary;

        print("\r", .{});
        print("                                            ", .{});
        print("\r", .{});
        print("{s} {d:.2}", .{ currency.symbols, cost });
    }
}

fn warn_continue_with_defaults() void {
    print("WARNING: Could not locate the application data directory. Continuing with defaults.\n", .{});
}

const currency_codes: []const Currency = ([_]Currency{
    .{ .currency_code = "ALL", .country_and_currency = "Albania Lek", .symbols = "Lek" },
    .{ .currency_code = "AFN", .country_and_currency = "Afghanistan Afghani", .symbols = "؋" },
    .{ .currency_code = "ARS", .country_and_currency = "Argentina Peso", .symbols = "$" },
    .{ .currency_code = "AWG", .country_and_currency = "Aruba Guilder", .symbols = "ƒ" },
    .{ .currency_code = "AUD", .country_and_currency = "Australia Dollar", .symbols = "$" },
    .{ .currency_code = "AZN", .country_and_currency = "Azerbaijan Manat", .symbols = "₼" },
    .{ .currency_code = "BSD", .country_and_currency = "Bahamas Dollar", .symbols = "$" },
    .{ .currency_code = "BBD", .country_and_currency = "Barbados Dollar", .symbols = "$" },
    .{ .currency_code = "BYN", .country_and_currency = "Belarus Ruble", .symbols = "Br" },
    .{ .currency_code = "BZD", .country_and_currency = "Belize Dollar", .symbols = "BZ$" },
    .{ .currency_code = "BMD", .country_and_currency = "Bermuda Dollar", .symbols = "$" },
    .{ .currency_code = "BOB", .country_and_currency = "Bolivia Bolíviano", .symbols = "$b" },
    .{ .currency_code = "BAM", .country_and_currency = "Bosnia and Herzegovina Convertible Mark", .symbols = "KM" },
    .{ .currency_code = "BWP", .country_and_currency = "Botswana Pula", .symbols = "P" },
    .{ .currency_code = "BGN", .country_and_currency = "Bulgaria Lev", .symbols = "лв" },
    .{ .currency_code = "BRL", .country_and_currency = "Brazil Real", .symbols = "R$" },
    .{ .currency_code = "BND", .country_and_currency = "Brunei Darussalam Dollar", .symbols = "$" },
    .{ .currency_code = "KHR", .country_and_currency = "Cambodia Riel", .symbols = "៛" },
    .{ .currency_code = "CAD", .country_and_currency = "Canada Dollar", .symbols = "$" },
    .{ .currency_code = "KYD", .country_and_currency = "Cayman Islands Dollar", .symbols = "$" },
    .{ .currency_code = "CLP", .country_and_currency = "Chile Peso", .symbols = "$" },
    .{ .currency_code = "CNY", .country_and_currency = "China Yuan Renminbi", .symbols = "¥" },
    .{ .currency_code = "COP", .country_and_currency = "Colombia Peso", .symbols = "$" },
    .{ .currency_code = "CRC", .country_and_currency = "Costa Rica Colon", .symbols = "₡" },
    .{ .currency_code = "HRK", .country_and_currency = "Croatia Kuna", .symbols = "kn" },
    .{ .currency_code = "CUP", .country_and_currency = "Cuba Peso", .symbols = "₱" },
    .{ .currency_code = "CZK", .country_and_currency = "Czech Republic Koruna", .symbols = "Kč" },
    .{ .currency_code = "DKK", .country_and_currency = "Denmark Krone", .symbols = "kr" },
    .{ .currency_code = "DOP", .country_and_currency = "Dominican Republic Peso", .symbols = "RD$" },
    .{ .currency_code = "XCD", .country_and_currency = "East Caribbean Dollar", .symbols = "$" },
    .{ .currency_code = "EGP", .country_and_currency = "Egypt Pound", .symbols = "£" },
    .{ .currency_code = "SVC", .country_and_currency = "El Salvador Colon", .symbols = "$" },
    .{ .currency_code = "EUR", .country_and_currency = "Euro Member Countries", .symbols = "€" },
    .{ .currency_code = "FKP", .country_and_currency = "Falkland Islands (Malvinas) Pound", .symbols = "£" },
    .{ .currency_code = "FJD", .country_and_currency = "Fiji Dollar", .symbols = "$" },
    .{ .currency_code = "GHS", .country_and_currency = "Ghana Cedi", .symbols = "¢" },
    .{ .currency_code = "GIP", .country_and_currency = "Gibraltar Pound", .symbols = "£" },
    .{ .currency_code = "GTQ", .country_and_currency = "Guatemala Quetzal", .symbols = "Q" },
    .{ .currency_code = "GGP", .country_and_currency = "Guernsey Pound", .symbols = "£" },
    .{ .currency_code = "GYD", .country_and_currency = "Guyana Dollar", .symbols = "$" },
    .{ .currency_code = "HNL", .country_and_currency = "Honduras Lempira", .symbols = "L" },
    .{ .currency_code = "HKD", .country_and_currency = "Hong Kong Dollar", .symbols = "$" },
    .{ .currency_code = "HUF", .country_and_currency = "Hungary Forint", .symbols = "Ft" },
    .{ .currency_code = "ISK", .country_and_currency = "Iceland Krona", .symbols = "kr" },
    .{ .currency_code = "INR", .country_and_currency = "India Rupee", .symbols = "" },
    .{ .currency_code = "IDR", .country_and_currency = "Indonesia Rupiah", .symbols = "Rp" },
    .{ .currency_code = "IRR", .country_and_currency = "Iran Rial", .symbols = "﷼" },
    .{ .currency_code = "IMP", .country_and_currency = "Isle of Man Pound", .symbols = "£" },
    .{ .currency_code = "ILS", .country_and_currency = "Israel Shekel", .symbols = "₪" },
    .{ .currency_code = "JMD", .country_and_currency = "Jamaica Dollar", .symbols = "J$" },
    .{ .currency_code = "JPY", .country_and_currency = "Japan Yen", .symbols = "¥" },
    .{ .currency_code = "JEP", .country_and_currency = "Jersey Pound", .symbols = "£" },
    .{ .currency_code = "KZT", .country_and_currency = "Kazakhstan Tenge", .symbols = "лв" },
    .{ .currency_code = "KPW", .country_and_currency = "Korea (North) Won", .symbols = "₩" },
    .{ .currency_code = "KRW", .country_and_currency = "Korea (South) Won", .symbols = "₩" },
    .{ .currency_code = "KGS", .country_and_currency = "Kyrgyzstan Som", .symbols = "лв" },
    .{ .currency_code = "LAK", .country_and_currency = "Laos Kip", .symbols = "₭" },
    .{ .currency_code = "LBP", .country_and_currency = "Lebanon Pound", .symbols = "£" },
    .{ .currency_code = "LRD", .country_and_currency = "Liberia Dollar", .symbols = "$" },
    .{ .currency_code = "MKD", .country_and_currency = "Macedonia Denar", .symbols = "ден" },
    .{ .currency_code = "MYR", .country_and_currency = "Malaysia Ringgit", .symbols = "RM" },
    .{ .currency_code = "MUR", .country_and_currency = "Mauritius Rupee", .symbols = "₨" },
    .{ .currency_code = "MXN", .country_and_currency = "Mexico Peso", .symbols = "$" },
    .{ .currency_code = "MNT", .country_and_currency = "Mongolia Tughrik", .symbols = "₮" },
    .{ .currency_code = "MZN", .country_and_currency = "Mozambique Metical", .symbols = "MT" },
    .{ .currency_code = "NAD", .country_and_currency = "Namibia Dollar", .symbols = "$" },
    .{ .currency_code = "NPR", .country_and_currency = "Nepal Rupee", .symbols = "₨" },
    .{ .currency_code = "ANG", .country_and_currency = "Netherlands Antilles Guilder", .symbols = "ƒ" },
    .{ .currency_code = "NZD", .country_and_currency = "New Zealand Dollar", .symbols = "$" },
    .{ .currency_code = "NIO", .country_and_currency = "Nicaragua Cordoba", .symbols = "C$" },
    .{ .currency_code = "NGN", .country_and_currency = "Nigeria Naira", .symbols = "₦" },
    .{ .currency_code = "NOK", .country_and_currency = "Norway Krone", .symbols = "kr" },
    .{ .currency_code = "OMR", .country_and_currency = "Oman Rial", .symbols = "﷼" },
    .{ .currency_code = "PKR", .country_and_currency = "Pakistan Rupee", .symbols = "₨" },
    .{ .currency_code = "PAB", .country_and_currency = "Panama Balboa", .symbols = "B/." },
    .{ .currency_code = "PYG", .country_and_currency = "Paraguay Guarani", .symbols = "Gs" },
    .{ .currency_code = "PEN", .country_and_currency = "Peru Sol", .symbols = "S/." },
    .{ .currency_code = "PHP", .country_and_currency = "Philippines Peso", .symbols = "₱" },
    .{ .currency_code = "PLN", .country_and_currency = "Poland Zloty", .symbols = "zł" },
    .{ .currency_code = "QAR", .country_and_currency = "Qatar Riyal", .symbols = "﷼" },
    .{ .currency_code = "RON", .country_and_currency = "Romania Leu", .symbols = "lei" },
    .{ .currency_code = "RUB", .country_and_currency = "Russia Ruble", .symbols = "₽" },
    .{ .currency_code = "SHP", .country_and_currency = "Saint Helena Pound", .symbols = "£" },
    .{ .currency_code = "SAR", .country_and_currency = "Saudi Arabia Riyal", .symbols = "﷼" },
    .{ .currency_code = "RSD", .country_and_currency = "Serbia Dinar", .symbols = "Дин." },
    .{ .currency_code = "SCR", .country_and_currency = "Seychelles Rupee", .symbols = "₨" },
    .{ .currency_code = "SGD", .country_and_currency = "Singapore Dollar", .symbols = "$" },
    .{ .currency_code = "SBD", .country_and_currency = "Solomon Islands Dollar", .symbols = "$" },
    .{ .currency_code = "SOS", .country_and_currency = "Somalia Shilling", .symbols = "S" },
    .{ .currency_code = "ZAR", .country_and_currency = "South Africa Rand", .symbols = "R" },
    .{ .currency_code = "LKR", .country_and_currency = "Sri Lanka Rupee", .symbols = "₨" },
    .{ .currency_code = "SEK", .country_and_currency = "Sweden Krona", .symbols = "kr" },
    .{ .currency_code = "CHF", .country_and_currency = "Switzerland Franc", .symbols = "CHF" },
    .{ .currency_code = "SRD", .country_and_currency = "Suriname Dollar", .symbols = "$" },
    .{ .currency_code = "SYP", .country_and_currency = "Syria Pound", .symbols = "£" },
    .{ .currency_code = "TWD", .country_and_currency = "Taiwan New Dollar", .symbols = "NT$" },
    .{ .currency_code = "THB", .country_and_currency = "Thailand Baht", .symbols = "฿" },
    .{ .currency_code = "TTD", .country_and_currency = "Trinidad and Tobago Dollar", .symbols = "TT$" },
    .{ .currency_code = "TRY", .country_and_currency = "Turkey Lira", .symbols = "" },
    .{ .currency_code = "TVD", .country_and_currency = "Tuvalu Dollar", .symbols = "$" },
    .{ .currency_code = "UAH", .country_and_currency = "Ukraine Hryvnia", .symbols = "₴" },
    .{ .currency_code = "GBP", .country_and_currency = "United Kingdom Pound", .symbols = "£" },
    .{ .currency_code = "USD", .country_and_currency = "United States Dollar", .symbols = "$" },
    .{ .currency_code = "UYU", .country_and_currency = "Uruguay Peso", .symbols = "$U" },
    .{ .currency_code = "UZS", .country_and_currency = "Uzbekistan Som", .symbols = "лв" },
    .{ .currency_code = "VEF", .country_and_currency = "Venezuela Bolívar", .symbols = "Bs" },
    .{ .currency_code = "VND", .country_and_currency = "Viet Nam Dong", .symbols = "₫" },
    .{ .currency_code = "YER", .country_and_currency = "Yemen Rial", .symbols = "﷼" },
    .{ .currency_code = "ZWD", .country_and_currency = "Zimbabwe Dollar", .symbols = "Z$" },
})[0..];
