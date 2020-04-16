defmodule StoreHall.FilterAcceptedOptions do
  require StoreHallWeb.Gettext
  alias StoreHallWeb.Gettext, as: Gettext

  @accepted_orders [
    :asc,
    :desc
    # :asc_nulls_last,        # :asc_nulls_first,        # :desc_nulls_last,        # :desc_nulls_first
  ]

  def to_accepted_orders(atom, _default) when atom in @accepted_orders, do: atom
  def to_accepted_orders(_string, default), do: default
  def accepted_orders(), do: @accepted_orders

  def accepted_sorting(),
    do: [
      {Gettext.gettext("price desc"), "price:desc"},
      {Gettext.gettext("price asc"), "price:asc"},
      {Gettext.gettext("discount desc"), "discount:desc"},
      {Gettext.gettext("discount asc"), "discount:asc"},
      {Gettext.gettext("rating desc"), "rating:desc"},
      {Gettext.gettext("rating asc"), "rating:asc"},
      {Gettext.gettext("expiration desc"), "expiration:desc"},
      {Gettext.gettext("expiration asc"), "expiration:asc"},
      {Gettext.gettext("inserted_at desc"), "inserted_at:desc"},
      {Gettext.gettext("inserted_at asc"), "inserted_at:аsc"},
      {Gettext.gettext("name desc"), "name:desc"},
      {Gettext.gettext("name asc"), "name:аsc"}
    ]

  def accepted_user_sorting(),
    do: [
      {Gettext.gettext("mail_credits_askprice desc"), "mail_credits_ask:desc"},
      {Gettext.gettext("mail_credits_ask asc"), "mail_credits_ask:asc"},
      {Gettext.gettext("rating desc"), "rating:desc"},
      {Gettext.gettext("rating asc"), "rating:asc"},
      {Gettext.gettext("last_activity desc"), "last_activity:desc"},
      {Gettext.gettext("last_activity asc"), "last_activity:asc"},
      {Gettext.gettext("inserted_at desc"), "inserted_at:desc"},
      {Gettext.gettext("inserted_at asc"), "inserted_at:аsc"}
    ]

  def accepted_merchant_type(),
    do: [
      {Gettext.gettext("Private seller"), "merch_private"},
      {Gettext.gettext("Producer"), "merch_producer"},
      {Gettext.gettext("Retailer"), "merch_retailer"}
    ]

  def accepted_gender(),
    do: [
      {"", ""},
      {Gettext.gettext("male"), "male"},
      {Gettext.gettext("female"), "female"},
      {Gettext.gettext("other"), "other"}
    ]

  def accepted_kids_age(),
    do: [
      {"", ""},
      {Gettext.gettext("Infant"), "infant"},
      {Gettext.gettext("Toddler"), "toddler"},
      {Gettext.gettext("Preschooler"), "pre_s"},
      {Gettext.gettext("Primаry school"), "prim_s"},
      {Gettext.gettext("Secondary school"), "sec_s"},
      {Gettext.gettext("High school"), "high_s"},
      {Gettext.gettext("Student"), "student"},
      {Gettext.gettext("Teen"), "teen"},
      {Gettext.gettext("Adult"), "adult"}
    ]

  def accepted_marital_status(),
    do: [
      {"", ""},
      {Gettext.gettext("Single"), "single"},
      {Gettext.gettext("relation"), "relation"},
      {Gettext.gettext("Married"), "married"},
      {Gettext.gettext("Separated"), "separated"},
      {Gettext.gettext("Widowed"), "widowed"},
      {Gettext.gettext("Divorced"), "divorced"}
    ]

  def accepted_interests(),
    do: [
      {"", ""},
      {Gettext.gettext("Board games"), "Board games"},
      {Gettext.gettext("Bodybuilding"), "Bodybuilding"},
      {Gettext.gettext("Chess"), "Chess"},
      {Gettext.gettext("Gambling"), "Gambling"},
      {Gettext.gettext("Golf"), "Golf"},
      {Gettext.gettext("Investing"), "Investing"},
      {Gettext.gettext("Martial arts"), "Martial arts"},
      {Gettext.gettext("Meditation"), "Meditation"},
      {Gettext.gettext("Mountain biking"), "Mountain biking"},
      {Gettext.gettext("Parachuting"), "Parachuting"},
      {Gettext.gettext("Running/Jogging"), "Running/Jogging"},
      {Gettext.gettext("Singing"), "Singing"},
      {Gettext.gettext("Acting/Drama"), "Acting/Drama"},
      {Gettext.gettext("Crafts"), "Crafts"},
      {Gettext.gettext("Dancing"), "Dancing"},
      {Gettext.gettext("Musical instrument"), "Musical instrument"},
      {Gettext.gettext("Origami"), "Origami"},
      {Gettext.gettext("Painting"), "Painting"},
      {Gettext.gettext("Photography"), "Photography"},
      {Gettext.gettext("Pottery"), "Pottery"},
      {Gettext.gettext("Childcare"), "Childcare"},
      {Gettext.gettext("Languages"), "Languages"},
      {Gettext.gettext("Online classes"), "Online classes"},
      {Gettext.gettext("Reading"), "Reading"},
      {Gettext.gettext("Volunteering"), "Volunteering"},
      {Gettext.gettext("Jigsaw puzzles"), "Jigsaw puzzles"},
      {Gettext.gettext("Tennis"), "Tennis"},
      {Gettext.gettext("Archery"), "Archery"},
      {Gettext.gettext("Backgammon"), "Backgammon"},
      {Gettext.gettext("Basketball"), "Basketball"},
      {Gettext.gettext("Car restoration"), "Car restoration"},
      {Gettext.gettext("Cooking"), "Cooking"},
      {Gettext.gettext("Landscaping"), "Landscaping"},
      {Gettext.gettext("Lego building"), "Lego building"},
      {Gettext.gettext("Robotics"), "Robotics"},
      {Gettext.gettext("Skydiving"), "Skydiving"},
      {Gettext.gettext("Cricket"), "Cricket"},
      {Gettext.gettext("Knitting"), "Knitting"},
      {Gettext.gettext("Skiing"), "Skiing"},
      {Gettext.gettext("Swimming"), "Swimming"},
      {Gettext.gettext("Yoga"), "Yoga"},
      {Gettext.gettext("Animals and pets"), "Animals and pets"},
      {Gettext.gettext("Football"), "Football"},
      {Gettext.gettext("Mountain climbing"), "Mountain climbing"},
      {Gettext.gettext("Paragliding"), "Paragliding"},
      {Gettext.gettext("Rock climbing"), "Rock climbing"},
      {Gettext.gettext("Socialising"), "Socialising"},
      {Gettext.gettext("Coding/Programming"), "Coding/Programming"},
      {Gettext.gettext("Drawing"), "Drawing"},
      {Gettext.gettext("Fishing"), "Fishing"},
      {Gettext.gettext("Hunting"), "Hunting"},
      {Gettext.gettext("Snooker/Pool"), "Snooker/Pool"},
      {Gettext.gettext("Video games"), "Video games"},
      {Gettext.gettext("Video production"), "Video production"},
      {Gettext.gettext("Cycling"), "Cycling"},
      {Gettext.gettext("Hiking"), "Hiking"},
      {Gettext.gettext("Model building"), "Model building"},
      {Gettext.gettext("Papermaking"), "Papermaking"},
      {Gettext.gettext("Squash"), "Squash"},
      {Gettext.gettext("Woodworking"), "Woodworking"},
      {Gettext.gettext("Amateur radio"), "Amateur radio"},
      {Gettext.gettext("Blogging"), "Blogging"},
      {Gettext.gettext("Calligraphy"), "Calligraphy"},
      {Gettext.gettext("Crossword puzzles"), "Crossword puzzles"},
      {Gettext.gettext("Surfing"), "Surfing"},
      {Gettext.gettext("Travelling"), "Travelling"},
      {Gettext.gettext("Amateur astronomy"), "Amateur astronomy"},
      {Gettext.gettext("Collecting"), "Collecting"},
      {Gettext.gettext("Gardening"), "Gardening"},
      {Gettext.gettext("Marathon running"), "Marathon running"},
      {Gettext.gettext("Recycling"), "recycling"},
      {Gettext.gettext("Sailing"), "sailing"}
    ]

  def accepted_job_sector(),
    do: [
      {"", ""},
      {Gettext.gettext("Авиация"), "Авиация"},
      {Gettext.gettext("Летища и Авиолинии"), "Летища и Авиолинии"},
      {Gettext.gettext("Автомобили"), "Автомобили"},
      {Gettext.gettext("Автосервизи"), "Автосервизи"},
      {Gettext.gettext("Бензиностанции"), "Бензиностанции"},
      {Gettext.gettext("Административни и офис дейности"), "Административни и офис дейности"},
      {Gettext.gettext("Архитектура"), "Архитектура"},
      {Gettext.gettext("Строителство"), "Строителство"},
      {Gettext.gettext("Градоустройство"), "Градоустройство"},
      {Gettext.gettext("Банки"), "Банки"},
      {Gettext.gettext("Кредитиране"), "Кредитиране"},
      {Gettext.gettext("Бизнес/Консултантски услуги"), "Бизнес/Консултантски услуги"},
      {Gettext.gettext("Дизайн"), "Дизайн"},
      {Gettext.gettext("Криейтив"), "Криейтив"},
      {Gettext.gettext("Видео и Анимация"), "Видео и Анимация"},
      {Gettext.gettext("Енергетика и Ютилитис (Ток/Вода/Парно/Газ)"),
       "Енергетика и Ютилитис (Ток/Вода/Парно/Газ)"},
      {Gettext.gettext("Застраховане"), "Застраховане"},
      {Gettext.gettext("Здравеопазване и фармация"), "Здравеопазване и фармация"},
      {Gettext.gettext("Изкуство"), "Изкуство"},
      {Gettext.gettext("Развлечение"), "Развлечение"},
      {Gettext.gettext("Изследователска и Развойна дейност (R&D)"),
       "Изследователска и Развойна дейност (R&D)"},
      {Gettext.gettext("Инженери"), "Инженери"},
      {Gettext.gettext("Институции, Държавна администрация"),
       "Институции, Държавна администрация"},
      {Gettext.gettext("ИТ - Административни дейности и продажби"),
       "ИТ - Административни дейности и продажби"},
      {Gettext.gettext("ИТ - Разработка/поддръжка на софтуер"),
       "ИТ - Разработка/поддръжка на софтуер"},
      {Gettext.gettext("ИТ - Разработка/поддръжка на хардуер"),
       "ИТ - Разработка/поддръжка на хардуер"},
      {Gettext.gettext("Контакт центрове (Call Centers)"), "Контакт центрове (Call Centers)"},
      {Gettext.gettext("Маркетинг"), "Маркетинг"},
      {Gettext.gettext("Медии"), "Медии"},
      {Gettext.gettext("Издателство"), "Издателство"},
      {Gettext.gettext("Мениджмънт"), "Мениджмънт"},
      {Gettext.gettext("Бизнес развитие"), "Бизнес развитие"},
      {Gettext.gettext("Морски и Речен транспорт"), "Морски и Речен транспорт"},
      {Gettext.gettext("Недвижими имоти"), "Недвижими имоти"},
      {Gettext.gettext("Образование"), "Образование"},
      {Gettext.gettext("Курсове"), "Курсове"},
      {Gettext.gettext("Преводи"), "Преводи"},
      {Gettext.gettext("Организации с нестопанска цел"), "Организации с нестопанска цел"},
      {Gettext.gettext("Почистване"), "Почистване"},
      {Gettext.gettext("Услуги за домакинството"), "Услуги за домакинството"},
      {Gettext.gettext("Право, Юридически услуги"), "Право, Юридически услуги"},
      {Gettext.gettext("Производство - Електроника, Електротехника, Машиностроене"),
       "Производство - Електроника, Електротехника, Машиностроене"},
      {Gettext.gettext("Производство - Мебели и Дърводелство"),
       "Производство - Мебели и Дърводелство"},
      {Gettext.gettext("Производство - Металургия и Минно дело"),
       "Производство - Металургия и Минно дело"},
      {Gettext.gettext("Производство - Текстил и Облеклa"), "Производство - Текстил и Облеклa"},
      {Gettext.gettext("Производство - Фармация"), "Производство - Фармация"},
      {Gettext.gettext("Производство - Химия и Горива"), "Производство - Химия и Горива"},
      {Gettext.gettext("Производство - Храни и Напитки"), "Производство - Храни и Напитки"},
      {Gettext.gettext("Производство - Друго"), "Производство - Друго"},
      {Gettext.gettext("Резервации и Туризъм"), "Резервации и Туризъм"},
      {Gettext.gettext("Реклама, PR"), "Реклама, PR"},
      {Gettext.gettext("Ремонтни и Монтажни дейности"), "Ремонтни и Монтажни дейности"},
      {Gettext.gettext("Ресторанти, Кетъринг"), "Ресторанти, Кетъринг"},
      {Gettext.gettext("Салони за красота"), "Салони за красота"},
      {Gettext.gettext("Селско и горско стопанство, Рибовъдство"),
       "Селско и горско стопанство, Рибовъдство"},
      {Gettext.gettext("Сигурност и Охрана"), "Сигурност и Охрана"},
      {Gettext.gettext("Спорт"), "Спорт"},
      {Gettext.gettext("Кинезитерапия"), "Кинезитерапия"},
      {Gettext.gettext("Счетоводство"), "Счетоводство"},
      {Gettext.gettext("Одит"), "Одит"},
      {Gettext.gettext("Финанси"), "Финанси"},
      {Gettext.gettext("Телекомуникации - административни дейности и продажби"),
       "Телекомуникации - административни дейности и продажби"},
      {Gettext.gettext("Телекомуникации - инженери и техници"),
       "Телекомуникации - инженери и техници"},
      {Gettext.gettext("Транспорт"), "Транспорт"},
      {Gettext.gettext("Логистика"), "Логистика"},
      {Gettext.gettext("Спедиция"), "Спедиция"},
      {Gettext.gettext("Търговия и продажби"), "Търговия и продажби"},
      {Gettext.gettext("Физически труд"), "Физически труд"},
      {Gettext.gettext("Ръчен труд"), "Ръчен труд"},
      {Gettext.gettext("Хотели"), "Хотели"},
      {Gettext.gettext("Човешки ресурси"), "Човешки ресурси"},
      {Gettext.gettext("Шофьори"), "Шофьори"},
      {Gettext.gettext("Куриери"), "Куриери"}
    ]
end
