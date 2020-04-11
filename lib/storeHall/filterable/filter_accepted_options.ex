defmodule StoreHall.FilterAcceptedOptions do
  defmacro __using__(_opts) do
    quote do
      @accepted_orders [
        :asc,
        :desc
        # :asc_nulls_last,
        # :asc_nulls_first,
        # :desc_nulls_last,
        # :desc_nulls_first
      ]
      @accepted_fields [:id, :inserted_at, :updated_at, :name]

      @accepted_sorting [
        {"price desc", "price:desc"},
        {"price asc", "price:asc"},
        {"discount desc", "discount:desc"},
        {"discount asc", "discount:asc"},
        {"rating desc", "rating:desc"},
        {"rating asc", "rating:asc"},
        {"expiration desc", "expiration:desc"},
        {"expiration asc", "expiration:asc"},
        {"inserted_at desc", "inserted_at:desc"},
        {"inserted_at asc", "inserted_at:аsc"},
        {"name desc", "name:desc"},
        {"name asc", "name:аsc"}
      ]
      def accepted_sorting(), do: @accepted_sorting |> format_options

      @accepted_merchant_type [
        {"Private seller", "merch_private"},
        {"Producer", "merch_producer"},
        {"Retailer", "merch_retailer"}
      ]
      def accepted_merchant_type(), do: @accepted_merchant_type |> format_options

      @accepted_gender [
        {"", ""},
        {"male", "male"},
        {"female", "female"},
        {"other", "other"}
      ]
      def accepted_gender(), do: @accepted_gender |> format_options

      @accepted_kids_age [
        {"", ""},
        {"Infant", "infant"},
        {"Toddler", "toddler"},
        {"Preschooler", "pre_s"},
        {"Primаry school", "prim_s"},
        {"Secondary school", "sec_s"},
        {"High school", "high_s"},
        {"Student", "student"},
        {"Teen", "teen"},
        {"Adult", "adult"}
      ]
      def accepted_kids_age(), do: @accepted_kids_age |> format_options

      @accepted_marital_status [
        {"", ""},
        {"Single", "single"},
        {"relation", "relation"},
        {"Married", "married"},
        {"Separated", "separated"},
        {"Widowed", "widowed"},
        {"Divorced", "divorced"}
      ]
      def accepted_marital_status(), do: @accepted_marital_status |> format_options

      @accepted_interests [
        {"", ""},
        {"Board games", "Board games"},
        {"Bodybuilding", "Bodybuilding"},
        {"Chess", "Chess"},
        {"Gambling", "Gambling"},
        {"Golf", "Golf"},
        {"Investing", "Investing"},
        {"Martial arts", "Martial arts"},
        {"Meditation", "Meditation"},
        {"Mountain biking", "Mountain biking"},
        {"Parachuting", "Parachuting"},
        {"Running/Jogging", "Running/Jogging"},
        {"Singing", "Singing"},
        {"Acting/Drama", "Acting/Drama"},
        {"Crafts", "Crafts"},
        {"Dancing", "Dancing"},
        {"Musical instrument", "Musical instrument"},
        {"Origami", "Origami"},
        {"Painting", "Painting"},
        {"Photography", "Photography"},
        {"Pottery", "Pottery"},
        {"Childcare", "Childcare"},
        {"Languages", "Languages"},
        {"Online classes", "Online classes"},
        {"Reading", "Reading"},
        {"Volunteering", "Volunteering"},
        {"Jigsaw puzzles", "Jigsaw puzzles"},
        {"Tennis", "Tennis"},
        {"Archery", "Archery"},
        {"Backgammon", "Backgammon"},
        {"Basketball", "Basketball"},
        {"Car restoration", "Car restoration"},
        {"Cooking", "Cooking"},
        {"Landscaping", "Landscaping"},
        {"Lego building", "Lego building"},
        {"Robotics", "Robotics"},
        {"Skydiving", "Skydiving"},
        {"Cricket", "Cricket"},
        {"Knitting", "Knitting"},
        {"Skiing", "Skiing"},
        {"Swimming", "Swimming"},
        {"Yoga", "Yoga"},
        {"Animals and pets", "Animals and pets"},
        {"Football", "Football"},
        {"Mountain climbing", "Mountain climbing"},
        {"Paragliding", "Paragliding"},
        {"Rock climbing", "Rock climbing"},
        {"Socialising", "Socialising"},
        {"Coding/Programming", "Coding/Programming"},
        {"Drawing", "Drawing"},
        {"Fishing", "Fishing"},
        {"Hunting", "Hunting"},
        {"Snooker/Pool", "Snooker/Pool"},
        {"Video games", "Video games"},
        {"Video production", "Video production"},
        {"Cycling", "Cycling"},
        {"Hiking", "Hiking"},
        {"Model building", "Model building"},
        {"Papermaking", "Papermaking"},
        {"Squash", "Squash"},
        {"Woodworking", "Woodworking"},
        {"Amateur radio", "Amateur radio"},
        {"Blogging", "Blogging"},
        {"Calligraphy", "Calligraphy"},
        {"Crossword puzzles", "Crossword puzzles"},
        {"Surfing", "Surfing"},
        {"Travelling", "Travelling"},
        {"Amateur astronomy", "Amateur astronomy"},
        {"Collecting", "Collecting"},
        {"Gardening", "Gardening"},
        {"Marathon running", "Marathon running"},
        {"Recycling", "recycling"},
        {"Sailing", "sailing"}
      ]
      def accepted_interests(), do: @accepted_interests |> format_options

      @accepted_job_sector [
        {"", ""},
        {"Авиация", "Авиация"},
        {"Летища и Авиолинии", "Летища и Авиолинии"},
        {"Автомобили", "Автомобили"},
        {"Автосервизи", "Автосервизи"},
        {"Бензиностанции", "Бензиностанции"},
        {"Административни и офис дейности", "Административни и офис дейности"},
        {"Архитектура", "Архитектура"},
        {"Строителство", "Строителство"},
        {"Градоустройство", "Градоустройство"},
        {"Банки", "Банки"},
        {"Кредитиране", "Кредитиране"},
        {"Бизнес/Консултантски услуги", "Бизнес/Консултантски услуги"},
        {"Дизайн", "Дизайн"},
        {"Криейтив", "Криейтив"},
        {"Видео и Анимация", "Видео и Анимация"},
        {"Енергетика и Ютилитис (Ток/Вода/Парно/Газ)",
         "Енергетика и Ютилитис (Ток/Вода/Парно/Газ)"},
        {"Застраховане", "Застраховане"},
        {"Здравеопазване и фармация", "Здравеопазване и фармация"},
        {"Изкуство", "Изкуство"},
        {"Развлечение", "Развлечение"},
        {"Изследователска и Развойна дейност (R&D)", "Изследователска и Развойна дейност (R&D)"},
        {"Инженери", "Инженери"},
        {"Институции, Държавна администрация", "Институции, Държавна администрация"},
        {"ИТ - Административни дейности и продажби", "ИТ - Административни дейности и продажби"},
        {"ИТ - Разработка/поддръжка на софтуер", "ИТ - Разработка/поддръжка на софтуер"},
        {"ИТ - Разработка/поддръжка на хардуер", "ИТ - Разработка/поддръжка на хардуер"},
        {"Контакт центрове (Call Centers)", "Контакт центрове (Call Centers)"},
        {"Маркетинг", "Маркетинг"},
        {"Медии", "Медии"},
        {"Издателство", "Издателство"},
        {"Мениджмънт", "Мениджмънт"},
        {"Бизнес развитие", "Бизнес развитие"},
        {"Морски и Речен транспорт", "Морски и Речен транспорт"},
        {"Недвижими имоти", "Недвижими имоти"},
        {"Образование", "Образование"},
        {"Курсове", "Курсове"},
        {"Преводи", "Преводи"},
        {"Организации с нестопанска цел", "Организации с нестопанска цел"},
        {"Почистване", "Почистване"},
        {"Услуги за домакинството", "Услуги за домакинството"},
        {"Право, Юридически услуги", "Право, Юридически услуги"},
        {"Производство - Електроника, Електротехника, Машиностроене",
         "Производство - Електроника, Електротехника, Машиностроене"},
        {"Производство - Мебели и Дърводелство", "Производство - Мебели и Дърводелство"},
        {"Производство - Металургия и Минно дело", "Производство - Металургия и Минно дело"},
        {"Производство - Текстил и Облеклa", "Производство - Текстил и Облеклa"},
        {"Производство - Фармация", "Производство - Фармация"},
        {"Производство - Химия и Горива", "Производство - Химия и Горива"},
        {"Производство - Храни и Напитки", "Производство - Храни и Напитки"},
        {"Производство - Друго", "Производство - Друго"},
        {"Резервации и Туризъм", "Резервации и Туризъм"},
        {"Реклама, PR", "Реклама, PR"},
        {"Ремонтни и Монтажни дейности", "Ремонтни и Монтажни дейности"},
        {"Ресторанти, Кетъринг", "Ресторанти, Кетъринг"},
        {"Салони за красота", "Салони за красота"},
        {"Селско и горско стопанство, Рибовъдство", "Селско и горско стопанство, Рибовъдство"},
        {"Сигурност и Охрана", "Сигурност и Охрана"},
        {"Спорт", "Спорт"},
        {"Кинезитерапия", "Кинезитерапия"},
        {"Счетоводство", "Счетоводство"},
        {"Одит", "Одит"},
        {"Финанси", "Финанси"},
        {"Телекомуникации - административни дейности и продажби",
         "Телекомуникации - административни дейности и продажби"},
        {"Телекомуникации - инженери и техници", "Телекомуникации - инженери и техници"},
        {"Транспорт", "Транспорт"},
        {"Логистика", "Логистика"},
        {"Спедиция", "Спедиция"},
        {"Търговия и продажби", "Търговия и продажби"},
        {"Физически труд", "Физически труд"},
        {"Ръчен труд", "Ръчен труд"},
        {"Хотели", "Хотели"},
        {"Човешки ресурси", "Човешки ресурси"},
        {"Шофьори", "Шофьори"},
        {"Куриери ", "Куриери "}
      ]
      def accepted_job_sector(), do: @accepted_job_sector |> format_options

      def format_options(accepted_options) do
        accepted_options
        |> Enum.map(fn {k, v} -> {Gettext.gettext(StoreHallWeb.Gettext, k), v} end)
      end

      def to_accepted_orders(atom, _default) when atom in @accepted_orders, do: atom
      def to_accepted_orders(_string, default), do: default
      def accepted_orders(), do: @accepted_orders
    end
  end
end
