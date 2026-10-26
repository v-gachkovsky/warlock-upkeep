local _, ns = ...

ns.LOCALES.ukUA = {
    -- Chat messages
    ["disabled: this character is not a Warlock."] = "вимкнено: цей персонаж не чорнокнижник.",
    ["all frames locked."] = "усі рамки закріплено.",
    ["all frames unlocked (%s icons to move)."] = "усі рамки відкріплено (іконки рухаються так: %s).",
    ["preview on."] = "попередній перегляд увімкнено.",
    ["preview off."] = "попередній перегляд вимкнено.",
    ["simulated combat look on."] = "імітацію бою увімкнено.",
    ["simulated combat look off."] = "імітацію бою вимкнено.",
    ["cannot reset in combat."] = "не можна скинути налаштування в бою.",
    ["settings reset."] = "налаштування скинуто.",
    ["can't create the name font: %s"] = "не вдалося створити шрифт для імені: %s",
    ["can't play %s. Custom files need a full game restart after adding them."] = "не вдається відтворити %s. Після додавання власних файлів гру треба повністю перезапустити.",
    ["already added: %s"] = "уже додано: %s",
    ["added %s, but it can't be played yet: check the name or restart the game."] = "додано %s, але поки не відтворюється: перевірте назву або перезапустіть гру.",

    -- Minimap button
    ["Left click: settings"] = "Лівий клік: налаштування",
    ["Right click: toggle preview"] = "Правий клік: попередній перегляд",
    ["Shift + right click: simulate combat"] = "Shift + правий клік: імітація бою",
    ["Simulated combat look is ON"] = "Імітацію бою УВІМКНЕНО",
    ["Drag to move around the minimap"] = "Перетягніть, щоб пересунути по мінімапі",

    -- Icons and tooltips
    ["Demon Armor"] = "Демонічна броня",
    ["Healthstone"] = "Камінь здоров'я",
    ["Soulstone"] = "Камінь душі",
    ["Summon Demon"] = "Призов демона",
    ["Missing Demon Skin / Demon Armor / Fel Armor. Click to cast."] = "Немає Демонічної шкіри / Демонічної броні / Броні скверни. Клік - накласти.",
    ["No Healthstone in bags. Click to create the strongest one."] = "У сумках немає Каменя здоров'я. Клік - створити найсильніший.",
    ["No Soulstone in bags. Click to create the strongest one."] = "У сумках немає Каменя душі. Клік - створити найсильніший.",
    ["Soulstone is not applied. Click to use it on your"] = "Камінь душі не накладено. Клік - використати на",
    ["friendly target (or yourself if none)."] = "дружню ціль (або на себе, якщо цілі немає).",
    ["Soulstone target"] = "Ціль Каменя душі",
    ["No demon summoned."] = "Демона не призвано.",
    ["Not learned yet (shown in preview only)."] = "Ще не вивчено (видно лише в попередньому перегляді).",
    ["%s to move"] = "%s - пересунути",
    ["Soul Shards"] = "Осколки душ",
    ["In bags"] = "У сумках",
    ["Recommended"] = "Рекомендовано",
    ["Demon summon"] = "Призов демона",
    ["Spare"] = "Запас",
    ["Low threshold"] = "Поріг нестачі",
    ["Drag to move"] = "Перетягніть, щоб пересунути",

    -- Grimoires
    ["Imp"] = "Імп",
    ["Voidwalker"] = "Демон Безодні",
    ["Succubus"] = "Сукуба",
    ["Felhunter"] = "Мисливець Скверни",
    ["Incubus"] = "Інкуб",
    ["Felguard"] = "Страж Скверни",
    ["already knows %s"] = "уже знає %s",
    ["%s (Rank %d)"] = "%s (ранг %d)",
    ["doesn't know it yet"] = "ще не знає",
    ["knows Rank %d, not this one"] = "знає ранг %d, а не цей",
    ["summon it once to check"] = "призвіть його раз, щоб перевірити",
    ["you can't summon it yet"] = "ви ще не можете його призвати",

    -- Lists
    ["English"] = "English",
    ["Right-drag"] = "Перетягування правою кнопкою",
    ["Shift + left-drag"] = "Shift + перетягування лівою",
    ["Ctrl + left-drag"] = "Ctrl + перетягування лівою",
    ["Alt + left-drag"] = "Alt + перетягування лівою",
    ["Cmd + left-drag"] = "Cmd + перетягування лівою",
    ["Click"] = "Клік",
    ["Shift + Click"] = "Shift + клік",
    ["Ctrl + Click"] = "Ctrl + клік",
    ["Alt + Click"] = "Alt + клік",
    ["Cmd + Click"] = "Cmd + клік",
    ["Friz Quadrata (Cyrillic)"] = "Friz Quadrata (кирилиця)",
    ["None"] = "Немає",
    ["Outline"] = "Контур",
    ["Thick outline"] = "Товстий контур",
    ["Proc (Cooldown Manager)"] = "Прок (як у Менеджері перезарядок)",
    ["Running lines"] = "Біжучі лінії",
    ["Pulsing border"] = "Пульсуюча рамка",
    ["Fill icon"] = "Заливка іконки",
    ["Outline + fill"] = "Контур + заливка",
    ["Raid Warning"] = "Рейдове попередження",
    ["Ready Check"] = "Перевірка готовності",
    ["Alarm Clock 1"] = "Будильник 1",
    ["Alarm Clock 2"] = "Будильник 2",
    ["Alarm Clock 3"] = "Будильник 3",
    ["Boss Emote"] = "Емоція боса",
    ["Boss Whisper"] = "Шепіт боса",
    ["Queue Ready"] = "Черга готова",
    ["Level Up"] = "Новий рівень",
    ["Group Invite"] = "Запрошення в групу",
    ["Auction House"] = "Аукціон",
    ["Toast"] = "Сповіщення",
    ["Whisper"] = "Шепіт",
    ["Map Ping"] = "Сигнал на мапі",
    ["%s (custom)"] = "%s (власний)",
    ["(none)"] = "(немає)",
    ["(not learned)"] = "(не вивчено)",
    ["Same as click"] = "Як для кліку",

    -- Settings: general
    ["Open settings (/wu)"] = "Відкрити налаштування (/wu)",
    ["General"] = "Загальне",
    ["Language"] = "Мова",
    ["Preview mode (show all icons for positioning)"] = "Попередній перегляд (показати всі іконки для розміщення)",
    ["Simulate combat (opacity, highlight, hiding, click-through)"] = "Імітація бою (прозорість, підсвітка, приховування, прозорість для кліків)",
    ["Show minimap button"] = "Показувати кнопку біля мінімапи",
    ["Lock minimap button position"] = "Закріпити кнопку біля мінімапи",
    ["Move icons with"] = "Пересування іконок",
    ["Hide all icons while on a flight path"] = "Ховати всі іконки під час польоту",
    ["Snap frames to each other (top / bottom / center, side by side)"] = "Прилипання рамок одна до одної (верх / низ / центр, поруч)",
    ["Snap distance"] = "Відстань прилипання",
    ["Gap between snapped frames"] = "Проміжок між рамками",
    ["Combat"] = "Бій",
    ["Highlight in combat"] = "Підсвічувати в бою",
    ["Click-through in combat (target / turn the camera through icons)"] = "Прозорість для кліків у бою (ціль / камера крізь іконки)",
    ["Hide icons in combat"] = "Ховати іконки в бою",
    ["Opacity in combat, %"] = "Непрозорість у бою, %",
    ["Opacity out of combat, %"] = "Непрозорість поза боєм, %",
    ["Click-through can't change during a fight (the game locks mouse input in combat): it applies after combat. " ..
        "Hiding applies at once, but icons hidden when the fight started stay hidden until it ends. " ..
        "Without click-through, icons are clickable in combat, and a faded-out icon still takes clicks at its spot."] =
        "Прозорість для кліків не змінюється під час бою (гра блокує мишу в бою): вона застосується після бою. " ..
        "Приховування діє одразу, але іконки, приховані на початку бою, лишаються прихованими до його кінця. " ..
        "Без прозорості для кліків іконки клікабельні в бою, і навіть прозора іконка ловить кліки на своєму місці.",
    ["Appearance"] = "Вигляд",
    ["Highlight type"] = "Тип підсвітки",
    ["Outline style"] = "Стиль контуру",
    ["Fill opacity, %"] = "Непрозорість заливки, %",
    ["Lock all"] = "Закріпити все",
    ["Unlock all"] = "Відкріпити все",
    ["Reset settings"] = "Скинути налаштування",
    ["Icons: left click performs the action; they are moved as set in \"Move icons with\" (only when unlocked). " ..
        "If a modifier is used for moving, clicks with that modifier do nothing while the icon is unlocked. " ..
        "Labels and the shard counter are moved with left-drag. Changes made in combat apply after combat."] =
        "Іконки: лівий клік виконує дію; пересуваються так, як задано в \"Пересування іконок\" (лише відкріплені). " ..
        "Якщо для пересування задано модифікатор, кліки з ним нічого не роблять, поки іконку відкріплено. " ..
        "Лейби та лічильник осколків пересуваються перетягуванням лівою кнопкою. Зміни, зроблені в бою, застосуються після бою.",

    -- Settings: sounds
    ["Custom sounds"] = "Власні звуки",
    ["Put .ogg or .mp3 files into World of Warcraft/<client>/Interface/WarlockUpkeepSounds/ and fully restart " ..
        "the game (a /reload doesn't find new files). Then add each file here by its name, e.g. alarm.ogg, " ..
        "or by a full path starting with Interface\\. Added files appear in every Sound list."] =
        "Покладіть файли .ogg або .mp3 у World of Warcraft/<клієнт>/Interface/WarlockUpkeepSounds/ і повністю перезапустіть " ..
        "гру (/reload нових файлів не бачить). Потім додайте кожен файл тут за назвою, наприклад alarm.ogg, " ..
        "або повним шляхом, що починається з Interface\\. Додані файли з'являться в кожному списку звуків.",
    ["Sound file"] = "Звуковий файл",
    ["Add"] = "Додати",
    ["Added files"] = "Додані файли",
    ["Remove selected"] = "Видалити обраний",
    ["Play sound"] = "Програвати звук",
    ["Sound"] = "Звук",
    ["Test"] = "Тест",
    ["Highlight (glow)"] = "Підсвітка",
    ["Highlight color"] = "Колір підсвітки",
    ["Enable"] = "Увімкнути",
    ["Lock position"] = "Закріпити позицію",
    ["Icon size"] = "Розмір іконки",
    ["Font"] = "Шрифт",

    -- Settings: armor
    ["Demon Armor / Demon Skin"] = "Демонічна броня / Демонічна шкіра",
    ["Important: add Demon Skin and Demon Armor to the Cooldown Manager's Tracked Buffs. " ..
        "In combat the game hides your buffs from addons, and the Cooldown Manager is what lets " ..
        "this icon notice the armor being removed or recast during a fight."] =
        "Важливо: додайте Демонічну шкіру та Демонічну броню до відстежуваних бафів у Менеджері перезарядок. " ..
        "У бою гра приховує ваші бафи від аддонів, і саме Менеджер перезарядок дає цій іконці " ..
        "помітити, що броню знято або накладено знову під час бою.",

    -- Settings: shards
    ["Soul Shard counter"] = "Лічильник осколків душ",
    ["Show shard icon"] = "Показувати іконку осколка",
    ["Background opacity, %"] = "Непрозорість фону, %",
    ["Spare shards"] = "Запасні осколки",
    ["Count Ritual of Summoning in recommended amount"] = "Враховувати Ритуал призову в рекомендованій кількості",
    ["Recommended now: |cffffd100%d|r  (%s%s+%d spare)"] = "Рекомендовано зараз: |cffffd100%d|r  (%s%s+%d запас)",
    ["Low threshold = recommended amount"] = "Поріг нестачі = рекомендована кількість",
    ["Highlight when fewer than"] = "Підсвітка, коли менше ніж",
    ["Show the threshold next to the count (current/threshold)"] = "Показувати поріг поруч із кількістю (є/поріг)",
    ["Text"] = "Текст",
    ["Font size"] = "Розмір шрифту",
    ["Text color"] = "Колір тексту",
    ["Text color when low"] = "Колір тексту при нестачі",
    ["Low shards alert"] = "Сповіщення про нестачу осколків",

    -- Settings: soulstone
    ["Hide while another warlock's Soulstone is on you"] = "Ховати, поки на вас Камінь душі іншого чорнокнижника",
    ["Remind to create a new Soulstone while one is applied"] = "Нагадувати створити новий Камінь душі, поки накладено попередній",
    ["State: Soulstone in bags but not applied"] = "Стан: Камінь душі в сумках, але не накладений",
    ["State: no Soulstone in bags"] = "Стан: у сумках немає Каменя душі",
    ["Soulstone target label"] = "Лейба цілі Каменя душі",
    ["Show label (name + timer) when used on another player"] = "Показувати лейбу (ім'я + таймер), коли накладено на іншого гравця",
    ["Show timer (without name) when Soulstone is on yourself (yours or another warlock's)"] = "Показувати таймер (без імені), коли Камінь душі на вас (ваш чи іншого чорнокнижника)",
    ["Lock label position"] = "Закріпити позицію лейби",
    ["Show Soulstone icon left of the timer"] = "Показувати іконку Каменя душі ліворуч від таймера",
    ["Name size"] = "Розмір імені",
    ["Timer size"] = "Розмір таймера",
    ["Timer color"] = "Колір таймера",
    ["Timer: warning zone"] = "Таймер: зона попередження",
    ["Timer: critical zone"] = "Таймер: критична зона",
    ["Starts at, seconds left"] = "Початок, секунд до кінця",
    ["Timer color in this zone"] = "Колір таймера в цій зоні",
    ["Play sound when the zone starts"] = "Програвати звук на початку зони",
    ["Timer: Soulstone ran out"] = "Таймер: Камінь душі закінчився",
    ["Play sound when the timer runs out"] = "Програвати звук, коли таймер закінчиться",
    ["Preview timer speed, x"] = "Швидкість у перегляді, x",
    ["The critical zone wins where the zones overlap. In preview mode the timer runs faster by the speed above " ..
        "(300x: a second per 5 minutes) and the sounds play on every cycle."] =
        "Там, де зони перетинаються, діє критична. У попередньому перегляді таймер іде швидше на вказану вище швидкість " ..
        "(300x: секунда за 5 хвилин), а звуки грають на кожному колі.",

    -- Settings: demon
    ["Demon (pet)"] = "Демон (пет)",
    ["Demon per click / modifier"] = "Демон для кліку / модифікатора",

    -- Settings: grimoires
    ["Grimoires"] = "Гримуари",
    ["Mark grimoires your demons already know at vendors"] = "Позначати в торговців гримуари, які ваші демони вже знають",
    ["Show what your demons know in grimoire tooltips"] = "Показувати в підказках гримуарів, що знають ваші демони",
    ["Demons checked: "] = "Перевірено демонів: ",
    ["none yet"] = "поки жодного",
    ["A demon's spells can only be read while it's summoned: summon each demon once, and from then on " ..
        "the addon remembers what it knows and keeps it up to date. At a vendor, learned grimoires get a " ..
        "check mark and turn grey; a question mark means that demon hasn't been checked yet. Grimoires for " ..
        "demons you can't summon yet are grey, without a mark. A bag icon means you already have that grimoire " ..
        "in your bags."] =
        "Заклинання демона можна прочитати, лише поки він призваний: призвіть кожного демона раз, і далі " ..
        "аддон пам'ятає, що він знає, і оновлює це. У торговця вивчені гримуари отримують галочку " ..
        "і стають сірими; знак питання означає, що цього демона ще не перевірено. Гримуари для демонів, " ..
        "яких ви ще не можете призвати, сірі й без позначки. Іконка сумки означає, що цей гримуар уже " ..
        "лежить у ваших сумках.",
}
