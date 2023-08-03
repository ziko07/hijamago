module CountryI18nHelper
  module_function

  def translate_country(country_code)
    country = ISO3166::Country[country_code]
    return country_code unless country

    locale = I18n.locale.to_s.downcase
    [locale, locale.split('-').first].each do |variant|
      name = country.translations[variant]
      return name if name.present?
    end
    return country.local_name
  end

  def translate_list(country_codes)
    lang = I18n.locale.to_s.downcase.split("-").first
    collator =  if TwitterCldr.supported_locale?(I18n.locale)
                  TwitterCldr::Collation::Collator.new(I18n.locale)
                elsif TwitterCldr.supported_locale?(lang)
                  TwitterCldr::Collation::Collator.new(lang)
                else
                  TwitterCldr::Collation::Collator.new
                end
    list = country_codes.map{|code| [translate_country(code), code]}
    list.map{ |s| [s, collator.get_sort_key(s.first)] }.sort_by(&:last).map(&:first)
  end

  def all_translated_countries
    translate_list(ISO3166::Country.codes)
  end

  def translated_shipping_countries
    translate_list(TransactionService::AvailableCurrencies::COUNTRY_SET_STRIPE_AND_PAYPAL)
  end

  def us_states
    [
      ['Alabama', 'AL'],
      ['Alaska', 'AK'],
      ['Arizona', 'AZ'],
      ['Arkansas', 'AR'],
      ['California', 'CA'],
      ['Colorado', 'CO'],
      ['Connecticut', 'CT'],
      ['Delaware', 'DE'],
      ['District of Columbia', 'DC'],
      ['Florida', 'FL'],
      ['Georgia', 'GA'],
      ['Hawaii', 'HI'],
      ['Idaho', 'ID'],
      ['Illinois', 'IL'],
      ['Indiana', 'IN'],
      ['Iowa', 'IA'],
      ['Kansas', 'KS'],
      ['Kentucky', 'KY'],
      ['Louisiana', 'LA'],
      ['Maine', 'ME'],
      ['Maryland', 'MD'],
      ['Massachusetts', 'MA'],
      ['Michigan', 'MI'],
      ['Minnesota', 'MN'],
      ['Mississippi', 'MS'],
      ['Missouri', 'MO'],
      ['Montana', 'MT'],
      ['Nebraska', 'NE'],
      ['Nevada', 'NV'],
      ['New Hampshire', 'NH'],
      ['New Jersey', 'NJ'],
      ['New Mexico', 'NM'],
      ['New York', 'NY'],
      ['North Carolina', 'NC'],
      ['North Dakota', 'ND'],
      ['Ohio', 'OH'],
      ['Oklahoma', 'OK'],
      ['Oregon', 'OR'],
      ['Pennsylvania', 'PA'],
      ['Puerto Rico', 'PR'],
      ['Rhode Island', 'RI'],
      ['South Carolina', 'SC'],
      ['South Dakota', 'SD'],
      ['Tennessee', 'TN'],
      ['Texas', 'TX'],
      ['Utah', 'UT'],
      ['Vermont', 'VT'],
      ['Virginia', 'VA'],
      ['Washington', 'WA'],
      ['West Virginia', 'WV'],
      ['Wisconsin', 'WI'],
      ['Wyoming', 'WY']
    ]
  end

  def ca_states
    ['AB', 'BC', 'MB', 'NB', 'NL', 'NS', 'NT', 'NU', 'ON', 'PE', 'QC', 'SK', 'YT'].map do |state|
      [I18n.t("canada_states.#{state}"), state]
    end
  end

  def au_states
    [
      ["Australian Capital Territory", "ACT"],
      ["New South Wales", "NSW"],
      ["Northern Territory", "NT"],
      ["Queensland", "QLD"],
      ["South Australia", "SA"],
      ["Tasmania", "TAS"],
      ["Victoria", "VIC"],
      ["Western Australia", "WA"]
    ]
  end

  def mx_states
    [
      ["Aguascalientes", "AG"],
      ["Baja California", "BC"],
      ["Baja California Sur", "BS"],
      ["Chihuahua", "CH"],
      ["Colima", "CL"],
      ["Campeche", "CM"],
      ["Coahuila", "CO"],
      ["Chiapas", "CS"],
      ["Federal District", "DF"],
      ["Durango", "DG"],
      ["Guerrero", "GR"],
      ["Guanajuato", "GT"],
      ["Hidalgo", "HG"],
      ["Jalisco", "JA"],
      ["México State", "ME"],
      ["Michoacán", "MI"],
      ["Morelos", "MO"],
      ["Nayarit", "NA"],
      ["Nuevo León", "NL"],
      ["Oaxaca", "OA"],
      ["Puebla", "PB"],
      ["Querétaro", "QE"],
      ["Quintana Roo", "QR"],
      ["Sinaloa", "SI"],
      ["San Luis Potosí", "SL"],
      ["Sonora", "SO"],
      ["Tabasco", "TB"],
      ["Tlaxcala", "TL"],
      ["Tamaulipas", "TM"],
      ["Veracruz", "VE"],
      ["Yucatán", "YU"],
      ["Zacatecas", "ZA"]
    ]
  end
end
