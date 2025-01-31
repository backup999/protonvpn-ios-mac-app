//
//  MapConstants.swift
//  vpncore - Created on 26.06.19.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of LegacyCommon.
//
//  vpncore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  vpncore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with LegacyCommon.  If not, see <https://www.gnu.org/licenses/>.

import CoreLocation

public enum MapConstants {

    public static let countryCoordinates: [String: CLLocationCoordinate2D] = [
        "AD": CLLocationCoordinate2D(latitude: 42.546245, longitude: 1.601554),
        "AE": CLLocationCoordinate2D(latitude: 24.091352, longitude: 54.123035),
        "AF": CLLocationCoordinate2D(latitude: 33.93911, longitude: 67.709953),
        "AG": CLLocationCoordinate2D(latitude: 17.060816, longitude: -61.796428),
        "AI": CLLocationCoordinate2D(latitude: 18.220554, longitude: -63.068615),
        "AL": CLLocationCoordinate2D(latitude: 41.135023, longitude: 20.059320),
        "AM": CLLocationCoordinate2D(latitude: 40.069099, longitude: 45.038189),
        "AN": CLLocationCoordinate2D(latitude: 12.226079, longitude: -69.060087),
        "AO": CLLocationCoordinate2D(latitude: -11.202692, longitude: 17.873887),
        "AQ": CLLocationCoordinate2D(latitude: -75.250973, longitude: -0.071389),
        "AR": CLLocationCoordinate2D(latitude: -37.157467, longitude: -64.316464),
        "AS": CLLocationCoordinate2D(latitude: -14.270972, longitude: -170.132217),
        "AT": CLLocationCoordinate2D(latitude: 47.648006, longitude: 14.844832),
        "AU": CLLocationCoordinate2D(latitude: -25.047944, longitude: 134.003347),
        "AW": CLLocationCoordinate2D(latitude: 12.52111, longitude: -69.968338),
        "AZ": CLLocationCoordinate2D(latitude: 40.352954, longitude: 47.772974),
        "BA": CLLocationCoordinate2D(latitude: 44.173743, longitude: 17.783922),
        "BB": CLLocationCoordinate2D(latitude: 13.193887, longitude: -59.543198),
        "BD": CLLocationCoordinate2D(latitude: 23.684994, longitude: 90.356331),
        "BE": CLLocationCoordinate2D(latitude: 50.615334, longitude: 4.524691),
        "BF": CLLocationCoordinate2D(latitude: 12.238333, longitude: -1.561593),
        "BG": CLLocationCoordinate2D(latitude: 42.676997, longitude: 25.429783),
        "BH": CLLocationCoordinate2D(latitude: 25.930414, longitude: 50.637772),
        "BI": CLLocationCoordinate2D(latitude: -3.373056, longitude: 29.918886),
        "BJ": CLLocationCoordinate2D(latitude: 9.30769, longitude: 2.315834),
        "BM": CLLocationCoordinate2D(latitude: 32.321384, longitude: -64.75737),
        "BN": CLLocationCoordinate2D(latitude: 4.535277, longitude: 114.727669),
        "BO": CLLocationCoordinate2D(latitude: -16.290154, longitude: -63.588653),
        "BR": CLLocationCoordinate2D(latitude: -9.683469, longitude: -52.308555),
        "BS": CLLocationCoordinate2D(latitude: 25.03428, longitude: -77.39628),
        "BT": CLLocationCoordinate2D(latitude: 27.514162, longitude: 90.433601),
        "BV": CLLocationCoordinate2D(latitude: -54.423199, longitude: 3.413194),
        "BW": CLLocationCoordinate2D(latitude: -22.328474, longitude: 24.684866),
        "BY": CLLocationCoordinate2D(latitude: 53.709807, longitude: 27.953389),
        "BZ": CLLocationCoordinate2D(latitude: 17.189877, longitude: -88.49765),
        "CA": CLLocationCoordinate2D(latitude: 58.111966, longitude: -102.032381),
        "CC": CLLocationCoordinate2D(latitude: -12.164165, longitude: 96.870956),
        "CD": CLLocationCoordinate2D(latitude: -4.038333, longitude: 21.758664),
        "CF": CLLocationCoordinate2D(latitude: 6.611111, longitude: 20.939444),
        "CG": CLLocationCoordinate2D(latitude: -0.228021, longitude: 15.827659),
        "CH": CLLocationCoordinate2D(latitude: 46.715779, longitude: 8.402655),
        "CI": CLLocationCoordinate2D(latitude: 7.539989, longitude: -5.54708),
        "CK": CLLocationCoordinate2D(latitude: -21.236736, longitude: -159.777671),
        "CL": CLLocationCoordinate2D(latitude: -34.572976, longitude: -71.095732),
        "CM": CLLocationCoordinate2D(latitude: 7.369722, longitude: 12.354722),
        "CN": CLLocationCoordinate2D(latitude: 35.86166, longitude: 104.195397),
        "CO": CLLocationCoordinate2D(latitude: 4.570868, longitude: -74.297333),
        "CR": CLLocationCoordinate2D(latitude: 9.845554, longitude: -83.862439),
        "CU": CLLocationCoordinate2D(latitude: 21.521757, longitude: -77.781167),
        "CV": CLLocationCoordinate2D(latitude: 16.002082, longitude: -24.013197),
        "CX": CLLocationCoordinate2D(latitude: -10.447525, longitude: 105.690449),
        "CY": CLLocationCoordinate2D(latitude: 35.017318, longitude: 33.202724),
        "CZ": CLLocationCoordinate2D(latitude: 49.739148, longitude: 15.334475),
        "DE": CLLocationCoordinate2D(latitude: 50.627542, longitude: 9.958450),
        "DJ": CLLocationCoordinate2D(latitude: 11.825138, longitude: 42.590275),
        "DK": CLLocationCoordinate2D(latitude: 55.959795, longitude: 10.077215),
        "DM": CLLocationCoordinate2D(latitude: 15.414999, longitude: -61.370976),
        "DO": CLLocationCoordinate2D(latitude: 18.735693, longitude: -70.162651),
        "DZ": CLLocationCoordinate2D(latitude: 28.033886, longitude: 1.659626),
        "EC": CLLocationCoordinate2D(latitude: -1.831239, longitude: -78.183406),
        "EE": CLLocationCoordinate2D(latitude: 58.674419, longitude: 25.394371),
        "EG": CLLocationCoordinate2D(latitude: 25.984796, longitude: 29.406176),
        "EH": CLLocationCoordinate2D(latitude: 24.215527, longitude: -12.885834),
        "ER": CLLocationCoordinate2D(latitude: 15.179384, longitude: 39.782334),
        "ES": CLLocationCoordinate2D(latitude: 39.8931705, longitude: -3.328424),
        "ET": CLLocationCoordinate2D(latitude: 9.145, longitude: 40.489673),
        "FI": CLLocationCoordinate2D(latitude: 64.010864, longitude: 26.627660),
        "FJ": CLLocationCoordinate2D(latitude: -16.578193, longitude: 179.414413),
        "FK": CLLocationCoordinate2D(latitude: -51.796253, longitude: -59.523613),
        "FM": CLLocationCoordinate2D(latitude: 7.425554, longitude: 150.550812),
        "FO": CLLocationCoordinate2D(latitude: 61.892635, longitude: -6.911806),
        "FR": CLLocationCoordinate2D(latitude: 46.648713, longitude: 2.621566),
        "GA": CLLocationCoordinate2D(latitude: -0.803689, longitude: 11.609444),
        "GB": CLLocationCoordinate2D(latitude: 53.199000, longitude: -1.912000), "UK": CLLocationCoordinate2D(latitude: 53.199000, longitude: -1.912000),
        "GD": CLLocationCoordinate2D(latitude: 12.262776, longitude: -61.604171),
        "GE": CLLocationCoordinate2D(latitude: 42.050170, longitude: 43.324267),
        "GF": CLLocationCoordinate2D(latitude: 3.933889, longitude: -53.125782),
        "GG": CLLocationCoordinate2D(latitude: 49.465691, longitude: -2.585278),
        "GH": CLLocationCoordinate2D(latitude: 7.946527, longitude: -1.023194),
        "GI": CLLocationCoordinate2D(latitude: 36.137741, longitude: -5.345374),
        "GL": CLLocationCoordinate2D(latitude: 71.706936, longitude: -42.604303),
        "GM": CLLocationCoordinate2D(latitude: 13.443182, longitude: -15.310139),
        "GN": CLLocationCoordinate2D(latitude: 9.945587, longitude: -9.696645),
        "GP": CLLocationCoordinate2D(latitude: 16.995971, longitude: -62.067641),
        "GQ": CLLocationCoordinate2D(latitude: 1.650801, longitude: 10.267895),
        "GR": CLLocationCoordinate2D(latitude: 39.069507, longitude: 22.034456),
        "GS": CLLocationCoordinate2D(latitude: -54.429579, longitude: -36.587909),
        "GT": CLLocationCoordinate2D(latitude: 15.783471, longitude: -90.230759),
        "GU": CLLocationCoordinate2D(latitude: 13.444304, longitude: 144.793731),
        "GW": CLLocationCoordinate2D(latitude: 11.803749, longitude: -15.180413),
        "GY": CLLocationCoordinate2D(latitude: 4.860416, longitude: -58.93018),
        "HK": CLLocationCoordinate2D(latitude: 22.358535, longitude: 114.142271),
        "HM": CLLocationCoordinate2D(latitude: -53.08181, longitude: 73.504158),
        "HN": CLLocationCoordinate2D(latitude: 15.199999, longitude: -86.241905),
        "HR": CLLocationCoordinate2D(latitude: 45.372686, longitude: 16.044798),
        "HT": CLLocationCoordinate2D(latitude: 18.971187, longitude: -72.285215),
        "HU": CLLocationCoordinate2D(latitude: 47.046255, longitude: 19.373862),
        "ID": CLLocationCoordinate2D(latitude: -3.187229, longitude: 119.851232),
        "IE": CLLocationCoordinate2D(latitude: 52.518882, longitude: -7.859928),
        "IL": CLLocationCoordinate2D(latitude: 31.467060, longitude: 34.814642),
        "IM": CLLocationCoordinate2D(latitude: 54.236107, longitude: -4.548056),
        "IN": CLLocationCoordinate2D(latitude: 23.041173, longitude: 78.891806),
        "IO": CLLocationCoordinate2D(latitude: -6.343194, longitude: 71.876519),
        "IQ": CLLocationCoordinate2D(latitude: 33.223191, longitude: 43.679291),
        "IR": CLLocationCoordinate2D(latitude: 32.427908, longitude: 53.688046),
        "IS": CLLocationCoordinate2D(latitude: 64.809637, longitude: -18.372633),
        "IT": CLLocationCoordinate2D(latitude: 41.659354, longitude: 14.258343),
        "JE": CLLocationCoordinate2D(latitude: 49.214439, longitude: -2.13125),
        "JM": CLLocationCoordinate2D(latitude: 18.109581, longitude: -77.297508),
        "JO": CLLocationCoordinate2D(latitude: 30.585164, longitude: 36.238414),
        "JP": CLLocationCoordinate2D(latitude: 38.280000, longitude: 140.460000),
        "KE": CLLocationCoordinate2D(latitude: -0.023559, longitude: 37.906193),
        "KG": CLLocationCoordinate2D(latitude: 41.20438, longitude: 74.766098),
        "KH": CLLocationCoordinate2D(latitude: 12.565679, longitude: 104.990963),
        "KI": CLLocationCoordinate2D(latitude: -3.370417, longitude: -168.734039),
        "KM": CLLocationCoordinate2D(latitude: -11.875001, longitude: 43.872219),
        "KN": CLLocationCoordinate2D(latitude: 17.357822, longitude: -62.782998),
        "KP": CLLocationCoordinate2D(latitude: 40.339852, longitude: 127.510093),
        "KR": CLLocationCoordinate2D(latitude: 36.458351, longitude: 127.855841),
        "KW": CLLocationCoordinate2D(latitude: 29.31166, longitude: 47.481766),
        "KY": CLLocationCoordinate2D(latitude: 19.513469, longitude: -80.566956),
        "KZ": CLLocationCoordinate2D(latitude: 48.019573, longitude: 66.923684),
        "LA": CLLocationCoordinate2D(latitude: 19.85627, longitude: 102.495496),
        "LB": CLLocationCoordinate2D(latitude: 33.854721, longitude: 35.862285),
        "LC": CLLocationCoordinate2D(latitude: 13.909444, longitude: -60.978893),
        "LI": CLLocationCoordinate2D(latitude: 47.166, longitude: 9.555373),
        "LK": CLLocationCoordinate2D(latitude: 7.873054, longitude: 80.771797),
        "LR": CLLocationCoordinate2D(latitude: 6.428055, longitude: -9.429499),
        "LS": CLLocationCoordinate2D(latitude: -29.609988, longitude: 28.233608),
        "LT": CLLocationCoordinate2D(latitude: 55.169438, longitude: 23.881275),
        "LU": CLLocationCoordinate2D(latitude: 49.777585, longitude: 6.094806),
        "LV": CLLocationCoordinate2D(latitude: 56.856496, longitude: 24.915373),
        "LY": CLLocationCoordinate2D(latitude: 26.3351, longitude: 17.228331),
        "MA": CLLocationCoordinate2D(latitude: 31.791702, longitude: -7.09262),
        "MC": CLLocationCoordinate2D(latitude: 43.750298, longitude: 7.412841),
        "MD": CLLocationCoordinate2D(latitude: 46.979304, longitude: 28.846518),
        "ME": CLLocationCoordinate2D(latitude: 42.708678, longitude: 19.37439),
        "MG": CLLocationCoordinate2D(latitude: -18.766947, longitude: 46.869107),
        "MH": CLLocationCoordinate2D(latitude: 7.131474, longitude: 171.184478),
        "MK": CLLocationCoordinate2D(latitude: 41.512352, longitude: 21.751619),
        "ML": CLLocationCoordinate2D(latitude: 17.570692, longitude: -3.996166),
        "MM": CLLocationCoordinate2D(latitude: 21.913965, longitude: 95.956223),
        "MN": CLLocationCoordinate2D(latitude: 46.862496, longitude: 103.846656),
        "MO": CLLocationCoordinate2D(latitude: 22.198745, longitude: 113.543873),
        "MP": CLLocationCoordinate2D(latitude: 17.33083, longitude: 145.38469),
        "MQ": CLLocationCoordinate2D(latitude: 14.641528, longitude: -61.024174),
        "MR": CLLocationCoordinate2D(latitude: 21.00789, longitude: -10.940835),
        "MS": CLLocationCoordinate2D(latitude: 16.742498, longitude: -62.187366),
        "MT": CLLocationCoordinate2D(latitude: 35.937496, longitude: 14.375416),
        "MU": CLLocationCoordinate2D(latitude: -20.348404, longitude: 57.552152),
        "MV": CLLocationCoordinate2D(latitude: 3.202778, longitude: 73.22068),
        "MW": CLLocationCoordinate2D(latitude: -13.254308, longitude: 34.301525),
        "MX": CLLocationCoordinate2D(latitude: 22.406570, longitude: -101.844884),
        "MY": CLLocationCoordinate2D(latitude: 3.988640, longitude: 102.064055),
        "MZ": CLLocationCoordinate2D(latitude: -18.665695, longitude: 35.529562),
        "NA": CLLocationCoordinate2D(latitude: -22.95764, longitude: 18.49041),
        "NC": CLLocationCoordinate2D(latitude: -20.904305, longitude: 165.618042),
        "NE": CLLocationCoordinate2D(latitude: 17.607789, longitude: 8.081666),
        "NF": CLLocationCoordinate2D(latitude: -29.040835, longitude: 167.954712),
        "NG": CLLocationCoordinate2D(latitude: 9.081999, longitude: 8.675277),
        "NI": CLLocationCoordinate2D(latitude: 12.865416, longitude: -85.207229),
        "NL": CLLocationCoordinate2D(latitude: 52.730774, longitude: 5.835204),
        "NO": CLLocationCoordinate2D(latitude: 61.457979, longitude: 8.971401),
        "NP": CLLocationCoordinate2D(latitude: 28.394857, longitude: 84.124008),
        "NR": CLLocationCoordinate2D(latitude: -0.522778, longitude: 166.931503),
        "NU": CLLocationCoordinate2D(latitude: -19.054445, longitude: -169.867233),
        "NZ": CLLocationCoordinate2D(latitude: -41.837112, longitude: 172.793343),
        "OM": CLLocationCoordinate2D(latitude: 21.512583, longitude: 55.923255),
        "PA": CLLocationCoordinate2D(latitude: 8.537981, longitude: -80.782127),
        "PE": CLLocationCoordinate2D(latitude: -9.189967, longitude: -75.015152),
        "PF": CLLocationCoordinate2D(latitude: -17.679742, longitude: -149.406843),
        "PG": CLLocationCoordinate2D(latitude: -6.314993, longitude: 143.95555),
        "PH": CLLocationCoordinate2D(latitude: 12.879721, longitude: 121.774017),
        "PK": CLLocationCoordinate2D(latitude: 30.375321, longitude: 69.345116),
        "PL": CLLocationCoordinate2D(latitude: 52.129535, longitude: 19.394454),
        "PM": CLLocationCoordinate2D(latitude: 46.941936, longitude: -56.27111),
        "PN": CLLocationCoordinate2D(latitude: -24.703615, longitude: -127.439308),
        "PR": CLLocationCoordinate2D(latitude: 18.220833, longitude: -66.590149),
        "PS": CLLocationCoordinate2D(latitude: 31.952162, longitude: 35.233154),
        "PT": CLLocationCoordinate2D(latitude: 39.658470, longitude: -8.244460),
        "PW": CLLocationCoordinate2D(latitude: 7.51498, longitude: 134.58252),
        "PY": CLLocationCoordinate2D(latitude: -23.442503, longitude: -58.443832),
        "QA": CLLocationCoordinate2D(latitude: 25.354826, longitude: 51.183884),
        "RE": CLLocationCoordinate2D(latitude: -21.115141, longitude: 55.536384),
        "RO": CLLocationCoordinate2D(latitude: 45.780363, longitude: 24.990706),
        "RS": CLLocationCoordinate2D(latitude: 44.030397, longitude: 20.804816),
        "RU": CLLocationCoordinate2D(latitude: 61.987429, longitude: 96.714855),
        "RW": CLLocationCoordinate2D(latitude: -1.940278, longitude: 29.873888),
        "SA": CLLocationCoordinate2D(latitude: 23.885942, longitude: 45.079162),
        "SB": CLLocationCoordinate2D(latitude: -9.64571, longitude: 160.156194),
        "SC": CLLocationCoordinate2D(latitude: -4.679574, longitude: 55.491977),
        "SD": CLLocationCoordinate2D(latitude: 12.862807, longitude: 30.217636),
        "SE": CLLocationCoordinate2D(latitude: 62.736314, longitude: 15.365470),
        "SG": CLLocationCoordinate2D(latitude: 1.356203, longitude: 103.828142),
        "SH": CLLocationCoordinate2D(latitude: -24.143474, longitude: -10.030696),
        "SI": CLLocationCoordinate2D(latitude: 45.988183, longitude: 14.644630),
        "SJ": CLLocationCoordinate2D(latitude: 77.553604, longitude: 23.670272),
        "SK": CLLocationCoordinate2D(latitude: 48.706566, longitude: 19.487012),
        "SL": CLLocationCoordinate2D(latitude: 8.460555, longitude: -11.779889),
        "SM": CLLocationCoordinate2D(latitude: 43.94236, longitude: 12.457777),
        "SN": CLLocationCoordinate2D(latitude: 14.497401, longitude: -14.452362),
        "SO": CLLocationCoordinate2D(latitude: 5.152149, longitude: 46.199616),
        "SR": CLLocationCoordinate2D(latitude: 3.919305, longitude: -56.027783),
        "SS": CLLocationCoordinate2D(latitude: 4.849999, longitude: 31.57),
        "ST": CLLocationCoordinate2D(latitude: 0.18636, longitude: 6.613081),
        "SV": CLLocationCoordinate2D(latitude: 13.794185, longitude: -88.89653),
        "SY": CLLocationCoordinate2D(latitude: 34.802075, longitude: 38.996815),
        "SZ": CLLocationCoordinate2D(latitude: -26.522503, longitude: 31.465866),
        "TC": CLLocationCoordinate2D(latitude: 21.694025, longitude: -71.797928),
        "TD": CLLocationCoordinate2D(latitude: 15.454166, longitude: 18.732207),
        "TF": CLLocationCoordinate2D(latitude: -49.280366, longitude: 69.348557),
        "TG": CLLocationCoordinate2D(latitude: 8.619543, longitude: 0.824782),
        "TH": CLLocationCoordinate2D(latitude: 15.660392, longitude: 101.520053),
        "TJ": CLLocationCoordinate2D(latitude: 38.861034, longitude: 71.276093),
        "TK": CLLocationCoordinate2D(latitude: -8.967363, longitude: -171.855881),
        "TL": CLLocationCoordinate2D(latitude: -8.874217, longitude: 125.727539),
        "TM": CLLocationCoordinate2D(latitude: 38.969719, longitude: 59.556278),
        "TN": CLLocationCoordinate2D(latitude: 33.886917, longitude: 9.537499),
        "TO": CLLocationCoordinate2D(latitude: -21.178986, longitude: -175.198242),
        "TR": CLLocationCoordinate2D(latitude: 39.061415, longitude: 35.124582),
        "TT": CLLocationCoordinate2D(latitude: 10.691803, longitude: -61.222503),
        "TV": CLLocationCoordinate2D(latitude: -7.109535, longitude: 177.64933),
        "TW": CLLocationCoordinate2D(latitude: 23.752054, longitude: 120.927318),
        "TZ": CLLocationCoordinate2D(latitude: -6.369028, longitude: 34.888822),
        "UA": CLLocationCoordinate2D(latitude: 49.395662, longitude: 30.980984),
        "UG": CLLocationCoordinate2D(latitude: 1.373333, longitude: 32.290275),
        "US": CLLocationCoordinate2D(latitude: 39.999733, longitude: -98.678503),
        "UY": CLLocationCoordinate2D(latitude: -32.522779, longitude: -55.765835),
        "UZ": CLLocationCoordinate2D(latitude: 41.377491, longitude: 64.585262),
        "VA": CLLocationCoordinate2D(latitude: 41.902916, longitude: 12.453389),
        "VC": CLLocationCoordinate2D(latitude: 12.984305, longitude: -61.287228),
        "VE": CLLocationCoordinate2D(latitude: 6.42375, longitude: -66.58973),
        "VG": CLLocationCoordinate2D(latitude: 18.420695, longitude: -64.639968),
        "VI": CLLocationCoordinate2D(latitude: 18.335765, longitude: -64.896335),
        "VN": CLLocationCoordinate2D(latitude: 13.318655, longitude: 108.368100),
        "VU": CLLocationCoordinate2D(latitude: -15.376706, longitude: 166.959158),
        "WF": CLLocationCoordinate2D(latitude: -13.768752, longitude: -177.156097),
        "WS": CLLocationCoordinate2D(latitude: -13.759029, longitude: -172.104629),
        "XK": CLLocationCoordinate2D(latitude: 42.602636, longitude: 20.902977),
        "YE": CLLocationCoordinate2D(latitude: 15.552727, longitude: 48.516388),
        "YT": CLLocationCoordinate2D(latitude: -12.8275, longitude: 45.166244),
        "ZA": CLLocationCoordinate2D(latitude: -29.140993, longitude: 24.367459),
        "ZM": CLLocationCoordinate2D(latitude: -13.133897, longitude: 27.849332),
        "ZW": CLLocationCoordinate2D(latitude: -19.015438, longitude: 29.154857)
    ]
}
