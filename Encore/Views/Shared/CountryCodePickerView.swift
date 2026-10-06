//
//  CountryCodePickerView.swift
//  Encore
//

import SwiftUI

// MARK: - Model

struct CountryDialCode: Identifiable, Hashable {
    let id: String        // ISO 3166-1 alpha-2
    let isoCode: String
    let name: String
    let flag: String      // emoji flag
    let dialCode: String  // e.g. "+506"

    static let all: [CountryDialCode] = [
        CountryDialCode(id: "AF", isoCode: "AF", name: "Afghanistan",           flag: "🇦🇫", dialCode: "+93"),
        CountryDialCode(id: "AL", isoCode: "AL", name: "Albania",               flag: "🇦🇱", dialCode: "+355"),
        CountryDialCode(id: "DZ", isoCode: "DZ", name: "Algeria",               flag: "🇩🇿", dialCode: "+213"),
        CountryDialCode(id: "AD", isoCode: "AD", name: "Andorra",               flag: "🇦🇩", dialCode: "+376"),
        CountryDialCode(id: "AO", isoCode: "AO", name: "Angola",                flag: "🇦🇴", dialCode: "+244"),
        CountryDialCode(id: "AG", isoCode: "AG", name: "Antigua & Barbuda",     flag: "🇦🇬", dialCode: "+1"),
        CountryDialCode(id: "AR", isoCode: "AR", name: "Argentina",             flag: "🇦🇷", dialCode: "+54"),
        CountryDialCode(id: "AM", isoCode: "AM", name: "Armenia",               flag: "🇦🇲", dialCode: "+374"),
        CountryDialCode(id: "AU", isoCode: "AU", name: "Australia",             flag: "🇦🇺", dialCode: "+61"),
        CountryDialCode(id: "AT", isoCode: "AT", name: "Austria",               flag: "🇦🇹", dialCode: "+43"),
        CountryDialCode(id: "AZ", isoCode: "AZ", name: "Azerbaijan",            flag: "🇦🇿", dialCode: "+994"),
        CountryDialCode(id: "BS", isoCode: "BS", name: "Bahamas",               flag: "🇧🇸", dialCode: "+1"),
        CountryDialCode(id: "BH", isoCode: "BH", name: "Bahrain",               flag: "🇧🇭", dialCode: "+973"),
        CountryDialCode(id: "BD", isoCode: "BD", name: "Bangladesh",            flag: "🇧🇩", dialCode: "+880"),
        CountryDialCode(id: "BB", isoCode: "BB", name: "Barbados",              flag: "🇧🇧", dialCode: "+1"),
        CountryDialCode(id: "BY", isoCode: "BY", name: "Belarus",               flag: "🇧🇾", dialCode: "+375"),
        CountryDialCode(id: "BE", isoCode: "BE", name: "Belgium",               flag: "🇧🇪", dialCode: "+32"),
        CountryDialCode(id: "BZ", isoCode: "BZ", name: "Belize",                flag: "🇧🇿", dialCode: "+501"),
        CountryDialCode(id: "BJ", isoCode: "BJ", name: "Benin",                 flag: "🇧🇯", dialCode: "+229"),
        CountryDialCode(id: "BT", isoCode: "BT", name: "Bhutan",                flag: "🇧🇹", dialCode: "+975"),
        CountryDialCode(id: "BO", isoCode: "BO", name: "Bolivia",               flag: "🇧🇴", dialCode: "+591"),
        CountryDialCode(id: "BA", isoCode: "BA", name: "Bosnia & Herzegovina",  flag: "🇧🇦", dialCode: "+387"),
        CountryDialCode(id: "BW", isoCode: "BW", name: "Botswana",              flag: "🇧🇼", dialCode: "+267"),
        CountryDialCode(id: "BR", isoCode: "BR", name: "Brazil",                flag: "🇧🇷", dialCode: "+55"),
        CountryDialCode(id: "BN", isoCode: "BN", name: "Brunei",                flag: "🇧🇳", dialCode: "+673"),
        CountryDialCode(id: "BG", isoCode: "BG", name: "Bulgaria",              flag: "🇧🇬", dialCode: "+359"),
        CountryDialCode(id: "BF", isoCode: "BF", name: "Burkina Faso",          flag: "🇧🇫", dialCode: "+226"),
        CountryDialCode(id: "BI", isoCode: "BI", name: "Burundi",               flag: "🇧🇮", dialCode: "+257"),
        CountryDialCode(id: "CV", isoCode: "CV", name: "Cabo Verde",            flag: "🇨🇻", dialCode: "+238"),
        CountryDialCode(id: "KH", isoCode: "KH", name: "Cambodia",              flag: "🇰🇭", dialCode: "+855"),
        CountryDialCode(id: "CM", isoCode: "CM", name: "Cameroon",              flag: "🇨🇲", dialCode: "+237"),
        CountryDialCode(id: "CA", isoCode: "CA", name: "Canada",                flag: "🇨🇦", dialCode: "+1"),
        CountryDialCode(id: "CF", isoCode: "CF", name: "Central African Rep.",  flag: "🇨🇫", dialCode: "+236"),
        CountryDialCode(id: "TD", isoCode: "TD", name: "Chad",                  flag: "🇹🇩", dialCode: "+235"),
        CountryDialCode(id: "CL", isoCode: "CL", name: "Chile",                 flag: "🇨🇱", dialCode: "+56"),
        CountryDialCode(id: "CN", isoCode: "CN", name: "China",                 flag: "🇨🇳", dialCode: "+86"),
        CountryDialCode(id: "CO", isoCode: "CO", name: "Colombia",              flag: "🇨🇴", dialCode: "+57"),
        CountryDialCode(id: "KM", isoCode: "KM", name: "Comoros",               flag: "🇰🇲", dialCode: "+269"),
        CountryDialCode(id: "CG", isoCode: "CG", name: "Congo",                 flag: "🇨🇬", dialCode: "+242"),
        CountryDialCode(id: "CR", isoCode: "CR", name: "Costa Rica",            flag: "🇨🇷", dialCode: "+506"),
        CountryDialCode(id: "HR", isoCode: "HR", name: "Croatia",               flag: "🇭🇷", dialCode: "+385"),
        CountryDialCode(id: "CU", isoCode: "CU", name: "Cuba",                  flag: "🇨🇺", dialCode: "+53"),
        CountryDialCode(id: "CY", isoCode: "CY", name: "Cyprus",                flag: "🇨🇾", dialCode: "+357"),
        CountryDialCode(id: "CZ", isoCode: "CZ", name: "Czech Republic",        flag: "🇨🇿", dialCode: "+420"),
        CountryDialCode(id: "DK", isoCode: "DK", name: "Denmark",               flag: "🇩🇰", dialCode: "+45"),
        CountryDialCode(id: "DJ", isoCode: "DJ", name: "Djibouti",              flag: "🇩🇯", dialCode: "+253"),
        CountryDialCode(id: "DM", isoCode: "DM", name: "Dominica",              flag: "🇩🇲", dialCode: "+1"),
        CountryDialCode(id: "DO", isoCode: "DO", name: "Dominican Republic",    flag: "🇩🇴", dialCode: "+1"),
        CountryDialCode(id: "EC", isoCode: "EC", name: "Ecuador",               flag: "🇪🇨", dialCode: "+593"),
        CountryDialCode(id: "EG", isoCode: "EG", name: "Egypt",                 flag: "🇪🇬", dialCode: "+20"),
        CountryDialCode(id: "SV", isoCode: "SV", name: "El Salvador",           flag: "🇸🇻", dialCode: "+503"),
        CountryDialCode(id: "GQ", isoCode: "GQ", name: "Equatorial Guinea",     flag: "🇬🇶", dialCode: "+240"),
        CountryDialCode(id: "ER", isoCode: "ER", name: "Eritrea",               flag: "🇪🇷", dialCode: "+291"),
        CountryDialCode(id: "EE", isoCode: "EE", name: "Estonia",               flag: "🇪🇪", dialCode: "+372"),
        CountryDialCode(id: "SZ", isoCode: "SZ", name: "Eswatini",              flag: "🇸🇿", dialCode: "+268"),
        CountryDialCode(id: "ET", isoCode: "ET", name: "Ethiopia",              flag: "🇪🇹", dialCode: "+251"),
        CountryDialCode(id: "FJ", isoCode: "FJ", name: "Fiji",                  flag: "🇫🇯", dialCode: "+679"),
        CountryDialCode(id: "FI", isoCode: "FI", name: "Finland",               flag: "🇫🇮", dialCode: "+358"),
        CountryDialCode(id: "FR", isoCode: "FR", name: "France",                flag: "🇫🇷", dialCode: "+33"),
        CountryDialCode(id: "GA", isoCode: "GA", name: "Gabon",                 flag: "🇬🇦", dialCode: "+241"),
        CountryDialCode(id: "GM", isoCode: "GM", name: "Gambia",                flag: "🇬🇲", dialCode: "+220"),
        CountryDialCode(id: "GE", isoCode: "GE", name: "Georgia",               flag: "🇬🇪", dialCode: "+995"),
        CountryDialCode(id: "DE", isoCode: "DE", name: "Germany",               flag: "🇩🇪", dialCode: "+49"),
        CountryDialCode(id: "GH", isoCode: "GH", name: "Ghana",                 flag: "🇬🇭", dialCode: "+233"),
        CountryDialCode(id: "GR", isoCode: "GR", name: "Greece",                flag: "🇬🇷", dialCode: "+30"),
        CountryDialCode(id: "GD", isoCode: "GD", name: "Grenada",               flag: "🇬🇩", dialCode: "+1"),
        CountryDialCode(id: "GT", isoCode: "GT", name: "Guatemala",             flag: "🇬🇹", dialCode: "+502"),
        CountryDialCode(id: "GN", isoCode: "GN", name: "Guinea",                flag: "🇬🇳", dialCode: "+224"),
        CountryDialCode(id: "GW", isoCode: "GW", name: "Guinea-Bissau",         flag: "🇬🇼", dialCode: "+245"),
        CountryDialCode(id: "GY", isoCode: "GY", name: "Guyana",                flag: "🇬🇾", dialCode: "+592"),
        CountryDialCode(id: "HT", isoCode: "HT", name: "Haiti",                 flag: "🇭🇹", dialCode: "+509"),
        CountryDialCode(id: "HN", isoCode: "HN", name: "Honduras",              flag: "🇭🇳", dialCode: "+504"),
        CountryDialCode(id: "HU", isoCode: "HU", name: "Hungary",               flag: "🇭🇺", dialCode: "+36"),
        CountryDialCode(id: "IS", isoCode: "IS", name: "Iceland",               flag: "🇮🇸", dialCode: "+354"),
        CountryDialCode(id: "IN", isoCode: "IN", name: "India",                 flag: "🇮🇳", dialCode: "+91"),
        CountryDialCode(id: "ID", isoCode: "ID", name: "Indonesia",             flag: "🇮🇩", dialCode: "+62"),
        CountryDialCode(id: "IR", isoCode: "IR", name: "Iran",                  flag: "🇮🇷", dialCode: "+98"),
        CountryDialCode(id: "IQ", isoCode: "IQ", name: "Iraq",                  flag: "🇮🇶", dialCode: "+964"),
        CountryDialCode(id: "IE", isoCode: "IE", name: "Ireland",               flag: "🇮🇪", dialCode: "+353"),
        CountryDialCode(id: "IL", isoCode: "IL", name: "Israel",                flag: "🇮🇱", dialCode: "+972"),
        CountryDialCode(id: "IT", isoCode: "IT", name: "Italy",                 flag: "🇮🇹", dialCode: "+39"),
        CountryDialCode(id: "JM", isoCode: "JM", name: "Jamaica",               flag: "🇯🇲", dialCode: "+1"),
        CountryDialCode(id: "JP", isoCode: "JP", name: "Japan",                 flag: "🇯🇵", dialCode: "+81"),
        CountryDialCode(id: "JO", isoCode: "JO", name: "Jordan",                flag: "🇯🇴", dialCode: "+962"),
        CountryDialCode(id: "KZ", isoCode: "KZ", name: "Kazakhstan",            flag: "🇰🇿", dialCode: "+7"),
        CountryDialCode(id: "KE", isoCode: "KE", name: "Kenya",                 flag: "🇰🇪", dialCode: "+254"),
        CountryDialCode(id: "KI", isoCode: "KI", name: "Kiribati",              flag: "🇰🇮", dialCode: "+686"),
        CountryDialCode(id: "KW", isoCode: "KW", name: "Kuwait",                flag: "🇰🇼", dialCode: "+965"),
        CountryDialCode(id: "KG", isoCode: "KG", name: "Kyrgyzstan",            flag: "🇰🇬", dialCode: "+996"),
        CountryDialCode(id: "LA", isoCode: "LA", name: "Laos",                  flag: "🇱🇦", dialCode: "+856"),
        CountryDialCode(id: "LV", isoCode: "LV", name: "Latvia",                flag: "🇱🇻", dialCode: "+371"),
        CountryDialCode(id: "LB", isoCode: "LB", name: "Lebanon",               flag: "🇱🇧", dialCode: "+961"),
        CountryDialCode(id: "LS", isoCode: "LS", name: "Lesotho",               flag: "🇱🇸", dialCode: "+266"),
        CountryDialCode(id: "LR", isoCode: "LR", name: "Liberia",               flag: "🇱🇷", dialCode: "+231"),
        CountryDialCode(id: "LY", isoCode: "LY", name: "Libya",                 flag: "🇱🇾", dialCode: "+218"),
        CountryDialCode(id: "LI", isoCode: "LI", name: "Liechtenstein",         flag: "🇱🇮", dialCode: "+423"),
        CountryDialCode(id: "LT", isoCode: "LT", name: "Lithuania",             flag: "🇱🇹", dialCode: "+370"),
        CountryDialCode(id: "LU", isoCode: "LU", name: "Luxembourg",            flag: "🇱🇺", dialCode: "+352"),
        CountryDialCode(id: "MG", isoCode: "MG", name: "Madagascar",            flag: "🇲🇬", dialCode: "+261"),
        CountryDialCode(id: "MW", isoCode: "MW", name: "Malawi",                flag: "🇲🇼", dialCode: "+265"),
        CountryDialCode(id: "MY", isoCode: "MY", name: "Malaysia",              flag: "🇲🇾", dialCode: "+60"),
        CountryDialCode(id: "MV", isoCode: "MV", name: "Maldives",              flag: "🇲🇻", dialCode: "+960"),
        CountryDialCode(id: "ML", isoCode: "ML", name: "Mali",                  flag: "🇲🇱", dialCode: "+223"),
        CountryDialCode(id: "MT", isoCode: "MT", name: "Malta",                 flag: "🇲🇹", dialCode: "+356"),
        CountryDialCode(id: "MH", isoCode: "MH", name: "Marshall Islands",      flag: "🇲🇭", dialCode: "+692"),
        CountryDialCode(id: "MR", isoCode: "MR", name: "Mauritania",            flag: "🇲🇷", dialCode: "+222"),
        CountryDialCode(id: "MU", isoCode: "MU", name: "Mauritius",             flag: "🇲🇺", dialCode: "+230"),
        CountryDialCode(id: "MX", isoCode: "MX", name: "Mexico",                flag: "🇲🇽", dialCode: "+52"),
        CountryDialCode(id: "FM", isoCode: "FM", name: "Micronesia",            flag: "🇫🇲", dialCode: "+691"),
        CountryDialCode(id: "MD", isoCode: "MD", name: "Moldova",               flag: "🇲🇩", dialCode: "+373"),
        CountryDialCode(id: "MC", isoCode: "MC", name: "Monaco",                flag: "🇲🇨", dialCode: "+377"),
        CountryDialCode(id: "MN", isoCode: "MN", name: "Mongolia",              flag: "🇲🇳", dialCode: "+976"),
        CountryDialCode(id: "ME", isoCode: "ME", name: "Montenegro",            flag: "🇲🇪", dialCode: "+382"),
        CountryDialCode(id: "MA", isoCode: "MA", name: "Morocco",               flag: "🇲🇦", dialCode: "+212"),
        CountryDialCode(id: "MZ", isoCode: "MZ", name: "Mozambique",            flag: "🇲🇿", dialCode: "+258"),
        CountryDialCode(id: "MM", isoCode: "MM", name: "Myanmar",               flag: "🇲🇲", dialCode: "+95"),
        CountryDialCode(id: "NA", isoCode: "NA", name: "Namibia",               flag: "🇳🇦", dialCode: "+264"),
        CountryDialCode(id: "NR", isoCode: "NR", name: "Nauru",                 flag: "🇳🇷", dialCode: "+674"),
        CountryDialCode(id: "NP", isoCode: "NP", name: "Nepal",                 flag: "🇳🇵", dialCode: "+977"),
        CountryDialCode(id: "NL", isoCode: "NL", name: "Netherlands",           flag: "🇳🇱", dialCode: "+31"),
        CountryDialCode(id: "NZ", isoCode: "NZ", name: "New Zealand",           flag: "🇳🇿", dialCode: "+64"),
        CountryDialCode(id: "NI", isoCode: "NI", name: "Nicaragua",             flag: "🇳🇮", dialCode: "+505"),
        CountryDialCode(id: "NE", isoCode: "NE", name: "Niger",                 flag: "🇳🇪", dialCode: "+227"),
        CountryDialCode(id: "NG", isoCode: "NG", name: "Nigeria",               flag: "🇳🇬", dialCode: "+234"),
        CountryDialCode(id: "NO", isoCode: "NO", name: "Norway",                flag: "🇳🇴", dialCode: "+47"),
        CountryDialCode(id: "OM", isoCode: "OM", name: "Oman",                  flag: "🇴🇲", dialCode: "+968"),
        CountryDialCode(id: "PK", isoCode: "PK", name: "Pakistan",              flag: "🇵🇰", dialCode: "+92"),
        CountryDialCode(id: "PW", isoCode: "PW", name: "Palau",                 flag: "🇵🇼", dialCode: "+680"),
        CountryDialCode(id: "PA", isoCode: "PA", name: "Panama",                flag: "🇵🇦", dialCode: "+507"),
        CountryDialCode(id: "PG", isoCode: "PG", name: "Papua New Guinea",      flag: "🇵🇬", dialCode: "+675"),
        CountryDialCode(id: "PY", isoCode: "PY", name: "Paraguay",              flag: "🇵🇾", dialCode: "+595"),
        CountryDialCode(id: "PE", isoCode: "PE", name: "Peru",                  flag: "🇵🇪", dialCode: "+51"),
        CountryDialCode(id: "PH", isoCode: "PH", name: "Philippines",           flag: "🇵🇭", dialCode: "+63"),
        CountryDialCode(id: "PL", isoCode: "PL", name: "Poland",                flag: "🇵🇱", dialCode: "+48"),
        CountryDialCode(id: "PT", isoCode: "PT", name: "Portugal",              flag: "🇵🇹", dialCode: "+351"),
        CountryDialCode(id: "QA", isoCode: "QA", name: "Qatar",                 flag: "🇶🇦", dialCode: "+974"),
        CountryDialCode(id: "RO", isoCode: "RO", name: "Romania",               flag: "🇷🇴", dialCode: "+40"),
        CountryDialCode(id: "RU", isoCode: "RU", name: "Russia",                flag: "🇷🇺", dialCode: "+7"),
        CountryDialCode(id: "RW", isoCode: "RW", name: "Rwanda",                flag: "🇷🇼", dialCode: "+250"),
        CountryDialCode(id: "KN", isoCode: "KN", name: "Saint Kitts & Nevis",   flag: "🇰🇳", dialCode: "+1"),
        CountryDialCode(id: "LC", isoCode: "LC", name: "Saint Lucia",           flag: "🇱🇨", dialCode: "+1"),
        CountryDialCode(id: "VC", isoCode: "VC", name: "Saint Vincent",         flag: "🇻🇨", dialCode: "+1"),
        CountryDialCode(id: "WS", isoCode: "WS", name: "Samoa",                 flag: "🇼🇸", dialCode: "+685"),
        CountryDialCode(id: "SM", isoCode: "SM", name: "San Marino",            flag: "🇸🇲", dialCode: "+378"),
        CountryDialCode(id: "ST", isoCode: "ST", name: "São Tomé & Príncipe",   flag: "🇸🇹", dialCode: "+239"),
        CountryDialCode(id: "SA", isoCode: "SA", name: "Saudi Arabia",          flag: "🇸🇦", dialCode: "+966"),
        CountryDialCode(id: "SN", isoCode: "SN", name: "Senegal",               flag: "🇸🇳", dialCode: "+221"),
        CountryDialCode(id: "RS", isoCode: "RS", name: "Serbia",                flag: "🇷🇸", dialCode: "+381"),
        CountryDialCode(id: "SC", isoCode: "SC", name: "Seychelles",            flag: "🇸🇨", dialCode: "+248"),
        CountryDialCode(id: "SL", isoCode: "SL", name: "Sierra Leone",          flag: "🇸🇱", dialCode: "+232"),
        CountryDialCode(id: "SG", isoCode: "SG", name: "Singapore",             flag: "🇸🇬", dialCode: "+65"),
        CountryDialCode(id: "SK", isoCode: "SK", name: "Slovakia",              flag: "🇸🇰", dialCode: "+421"),
        CountryDialCode(id: "SI", isoCode: "SI", name: "Slovenia",              flag: "🇸🇮", dialCode: "+386"),
        CountryDialCode(id: "SB", isoCode: "SB", name: "Solomon Islands",       flag: "🇸🇧", dialCode: "+677"),
        CountryDialCode(id: "SO", isoCode: "SO", name: "Somalia",               flag: "🇸🇴", dialCode: "+252"),
        CountryDialCode(id: "ZA", isoCode: "ZA", name: "South Africa",          flag: "🇿🇦", dialCode: "+27"),
        CountryDialCode(id: "SS", isoCode: "SS", name: "South Sudan",           flag: "🇸🇸", dialCode: "+211"),
        CountryDialCode(id: "ES", isoCode: "ES", name: "Spain",                 flag: "🇪🇸", dialCode: "+34"),
        CountryDialCode(id: "LK", isoCode: "LK", name: "Sri Lanka",             flag: "🇱🇰", dialCode: "+94"),
        CountryDialCode(id: "SD", isoCode: "SD", name: "Sudan",                 flag: "🇸🇩", dialCode: "+249"),
        CountryDialCode(id: "SR", isoCode: "SR", name: "Suriname",              flag: "🇸🇷", dialCode: "+597"),
        CountryDialCode(id: "SE", isoCode: "SE", name: "Sweden",                flag: "🇸🇪", dialCode: "+46"),
        CountryDialCode(id: "CH", isoCode: "CH", name: "Switzerland",           flag: "🇨🇭", dialCode: "+41"),
        CountryDialCode(id: "SY", isoCode: "SY", name: "Syria",                 flag: "🇸🇾", dialCode: "+963"),
        CountryDialCode(id: "TW", isoCode: "TW", name: "Taiwan",                flag: "🇹🇼", dialCode: "+886"),
        CountryDialCode(id: "TJ", isoCode: "TJ", name: "Tajikistan",            flag: "🇹🇯", dialCode: "+992"),
        CountryDialCode(id: "TZ", isoCode: "TZ", name: "Tanzania",              flag: "🇹🇿", dialCode: "+255"),
        CountryDialCode(id: "TH", isoCode: "TH", name: "Thailand",              flag: "🇹🇭", dialCode: "+66"),
        CountryDialCode(id: "TL", isoCode: "TL", name: "Timor-Leste",           flag: "🇹🇱", dialCode: "+670"),
        CountryDialCode(id: "TG", isoCode: "TG", name: "Togo",                  flag: "🇹🇬", dialCode: "+228"),
        CountryDialCode(id: "TO", isoCode: "TO", name: "Tonga",                 flag: "🇹🇴", dialCode: "+676"),
        CountryDialCode(id: "TT", isoCode: "TT", name: "Trinidad & Tobago",     flag: "🇹🇹", dialCode: "+1"),
        CountryDialCode(id: "TN", isoCode: "TN", name: "Tunisia",               flag: "🇹🇳", dialCode: "+216"),
        CountryDialCode(id: "TR", isoCode: "TR", name: "Turkey",                flag: "🇹🇷", dialCode: "+90"),
        CountryDialCode(id: "TM", isoCode: "TM", name: "Turkmenistan",          flag: "🇹🇲", dialCode: "+993"),
        CountryDialCode(id: "TV", isoCode: "TV", name: "Tuvalu",                flag: "🇹🇻", dialCode: "+688"),
        CountryDialCode(id: "UG", isoCode: "UG", name: "Uganda",                flag: "🇺🇬", dialCode: "+256"),
        CountryDialCode(id: "UA", isoCode: "UA", name: "Ukraine",               flag: "🇺🇦", dialCode: "+380"),
        CountryDialCode(id: "AE", isoCode: "AE", name: "United Arab Emirates",  flag: "🇦🇪", dialCode: "+971"),
        CountryDialCode(id: "GB", isoCode: "GB", name: "United Kingdom",        flag: "🇬🇧", dialCode: "+44"),
        CountryDialCode(id: "US", isoCode: "US", name: "United States",         flag: "🇺🇸", dialCode: "+1"),
        CountryDialCode(id: "UY", isoCode: "UY", name: "Uruguay",               flag: "🇺🇾", dialCode: "+598"),
        CountryDialCode(id: "UZ", isoCode: "UZ", name: "Uzbekistan",            flag: "🇺🇿", dialCode: "+998"),
        CountryDialCode(id: "VU", isoCode: "VU", name: "Vanuatu",               flag: "🇻🇺", dialCode: "+678"),
        CountryDialCode(id: "VE", isoCode: "VE", name: "Venezuela",             flag: "🇻🇪", dialCode: "+58"),
        CountryDialCode(id: "VN", isoCode: "VN", name: "Vietnam",               flag: "🇻🇳", dialCode: "+84"),
        CountryDialCode(id: "YE", isoCode: "YE", name: "Yemen",                 flag: "🇾🇪", dialCode: "+967"),
        CountryDialCode(id: "ZM", isoCode: "ZM", name: "Zambia",                flag: "🇿🇲", dialCode: "+260"),
        CountryDialCode(id: "ZW", isoCode: "ZW", name: "Zimbabwe",              flag: "🇿🇼", dialCode: "+263"),
    ]

    /// Look up country by ISO code (e.g. "CR" → Costa Rica).
    static func forIso(_ iso: String?) -> CountryDialCode? {
        guard let iso = iso, !iso.isEmpty else { return nil }
        return all.first(where: { $0.isoCode.uppercased() == iso.uppercased() })
    }

    /// Best guess from device locale (fallback: US).
    static func fromLocale() -> CountryDialCode {
        let iso = Locale.current.region?.identifier ?? "US"
        return all.first(where: { $0.isoCode == iso }) ?? all.first(where: { $0.isoCode == "US" })!
    }
}

// MARK: - Picker sheet

struct CountryCodePickerView: View {
    @Binding var selected: CountryDialCode
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [CountryDialCode] {
        if search.isEmpty { return CountryDialCode.all }
        let q = search.lowercased()
        return CountryDialCode.all.filter {
            $0.name.lowercased().contains(q) || $0.dialCode.contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { country in
                Button {
                    selected = country
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(country.flag)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(country.name)
                                .font(.body)
                                .foregroundStyle(Color.encoreText)
                            Text(country.dialCode)
                                .font(.caption)
                                .foregroundStyle(Color.encoreTextSecondary)
                        }
                        Spacer()
                        if country.isoCode == selected.isoCode {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.encorePrimary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $search, prompt: "Search country")
            .navigationTitle("Country Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
