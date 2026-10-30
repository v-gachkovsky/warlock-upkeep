local _, ns = ...

-- Spell / item IDs. Lists are ordered lowest rank -> highest rank (Classic Era, then TBC ranks).
-- Unknown IDs are harmless: only learned spells are used. New ranks or stones can be added here.
ns.data = {
    SOUL_SHARD = 6265,

    armor = {
        felArmor   = { 28176, 28189 },                            -- TBC; preferred when learned
        demonArmor = { 706, 1086, 11733, 11734, 11735, 27260 },
        demonSkin  = { 687, 696 },
    },
    armorDuration = 1800, -- all three last 30 minutes

    -- Demons the Pet icon can summon. `shard` = costs a Soul Shard.
    -- `list` holds replacements, last learned wins: Grimoire of Supremacy (Mists), Sayaad (Retail).
    demons = {
        { key = "imp",        spell = 688,   shard = false, list = { 688, 112866 } },
        { key = "voidwalker", spell = 697,   shard = true,  list = { 697, 112867 } },
        { key = "succubus",   spell = 712,   shard = true,  list = { 712, 112868, { spell = 366222, name = "Summon Sayaad" } } },
        { key = "felhunter",  spell = 691,   shard = true,  list = { 691, 112869 } },
        -- Not in Classic Era; `name` lets the addon find it by name if Forever uses another ID.
        { key = "incubus",    spell = 365349, shard = true, name = "Summon Incubus" },
        { key = "felguard",   spell = 30146, shard = true,  list = { 30146, 112870 } },
    },

    -- Grimoire of Sacrifice buff (Mists, Retail): the demon is sacrificed on purpose.
    petSacrificeBuffs = { 108503, 196099 },
    -- Demonic Sacrifice talent (Classic Era, TBC, Forever) and its buffs per demon: also a demon sacrificed on purpose.
    demonicSacrifice = 18788,
    demonicSacrificeBuffs = { 18789, 18790, 18791, 18792, 35701 },
    -- Soul Link talent and its buff on the caster.
    soulLink = 19028,
    soulLinkBuffs = { 25228, 19028 },
    -- Enslave Demon (Subjugate Demon in Classic Era): the debuff on the enslaved demon lasts up to 5 minutes.
    enslaveDemon = { 1098, 11725, 11726 },
    enslaveDuration = 300,

    -- The counter shows once Soul Shards can be gained.
    drainSoul = { 1120, 8288, 8289, 11675, 27217 },

    ritualOfSummoning = 698,

    -- Before Cataclysm every stone costs one Soul Shard to create.
    -- Mists and Retail only keep Create Healthstone (6201, item 5512).
    stones = {
        healthstone = {
            { spell = 6201,  items = { 5512, 19004, 19005, 224464 } }, -- Minor; Healthstone / Demonic Healthstone in Retail
            { spell = 6202,  items = { 5511, 19006, 19007 } }, -- Lesser
            { spell = 5699,  items = { 5509, 19008, 19009 } }, -- Healthstone
            { spell = 11729, items = { 5510, 19010, 19011 } }, -- Greater
            { spell = 11730, items = { 9421, 19012, 19013 } }, -- Major
            { spell = 27230, items = { 22103, 22104, 22105 } }, -- Master (TBC)
        },
        soulstone = {
            { spell = 693,   items = { 5232 } },  -- Minor
            { spell = 20752, items = { 16892 } }, -- Lesser
            { spell = 20755, items = { 16893 } }, -- Soulstone
            { spell = 20756, items = { 16895 } }, -- Greater
            { spell = 20757, items = { 16896 } }, -- Major
            { spell = 27238, items = { 22116 } }, -- Master (TBC)
        },
        firestone = {
            { spell = 6366,  items = { 1254 } },  -- Lesser
            { spell = 17951, items = { 13699 } }, -- Firestone
            { spell = 17952, items = { 13700 } }, -- Greater
            { spell = 17953, items = { 13701 } }, -- Major
            { spell = 27250, items = { 22128 } }, -- Master (TBC)
        },
        spellstone = {
            { spell = 2362,  items = { 5522 } },  -- Spellstone
            { spell = 17727, items = { 13602 } }, -- Greater
            { spell = 17728, items = { 13603 } }, -- Major
            { spell = 28172, items = { 22646 } }, -- Master (TBC)
        },
    },
    stoneOrder = { "healthstone", "soulstone", "firestone", "spellstone" },

    -- "Soulstone Resurrection" buff applied by using a Soulstone item.
    soulstoneBuffs = { 20707, 20762, 20763, 20764, 20765, 27239 },
    soulstoneDuration = 1800,
    -- Mists and Retail: Soulstone is a spell cast straight on the target (same ID as the buff).
    soulstoneSpell = 20707,
    soulstoneSpellDuration = 900,

    -- Grimoires (Classic Era, TBC, Forever): item -> { demon, pet spell it teaches, rank }.
    -- Taken from the game data (wago.tools): Classic Era and Forever have the same 59, TBC adds the rest.
    -- Rank 1 for spells without ranks.
    grimoires = {
        [16321] = { "imp", 6307, 1 }, -- Blood Pact 1
        [16322] = { "imp", 7804, 2 }, -- Blood Pact 2
        [16323] = { "imp", 7805, 3 }, -- Blood Pact 3
        [16324] = { "imp", 11766, 4 }, -- Blood Pact 4
        [16325] = { "imp", 11767, 5 }, -- Blood Pact 5
        [22180] = { "imp", 27268, 6 }, -- Blood Pact 6 (TBC)
        [16326] = { "imp", 2947, 1 }, -- Fire Shield 1
        [16327] = { "imp", 8316, 2 }, -- Fire Shield 2
        [16328] = { "imp", 8317, 3 }, -- Fire Shield 3
        [16329] = { "imp", 11770, 4 }, -- Fire Shield 4
        [16330] = { "imp", 11771, 5 }, -- Fire Shield 5
        [22181] = { "imp", 27269, 6 }, -- Fire Shield 6 (TBC)
        [16302] = { "imp", 7799, 2 }, -- Firebolt 2
        [16316] = { "imp", 7800, 3 }, -- Firebolt 3
        [16317] = { "imp", 7801, 4 }, -- Firebolt 4
        [16318] = { "imp", 7802, 5 }, -- Firebolt 5
        [16319] = { "imp", 11762, 6 }, -- Firebolt 6
        [16320] = { "imp", 11763, 7 }, -- Firebolt 7
        [22179] = { "imp", 27267, 8 }, -- Firebolt 8 (TBC)
        [16331] = { "imp", 4511, 1 }, -- Phase Shift
        [16357] = { "voidwalker", 17767, 1 }, -- Consume Shadows 1
        [16358] = { "voidwalker", 17850, 2 }, -- Consume Shadows 2
        [16359] = { "voidwalker", 17851, 3 }, -- Consume Shadows 3
        [16360] = { "voidwalker", 17852, 4 }, -- Consume Shadows 4
        [16361] = { "voidwalker", 17853, 5 }, -- Consume Shadows 5
        [16362] = { "voidwalker", 17854, 6 }, -- Consume Shadows 6
        [22184] = { "voidwalker", 27272, 7 }, -- Consume Shadows 7 (TBC)
        [16351] = { "voidwalker", 7812, 1 }, -- Sacrifice 1
        [16352] = { "voidwalker", 19438, 2 }, -- Sacrifice 2
        [16353] = { "voidwalker", 19440, 3 }, -- Sacrifice 3
        [16354] = { "voidwalker", 19441, 4 }, -- Sacrifice 4
        [16355] = { "voidwalker", 19442, 5 }, -- Sacrifice 5
        [16356] = { "voidwalker", 19443, 6 }, -- Sacrifice 6
        [22185] = { "voidwalker", 27273, 7 }, -- Sacrifice 7 (TBC)
        [16363] = { "voidwalker", 17735, 1 }, -- Suffering 1
        [16364] = { "voidwalker", 17750, 2 }, -- Suffering 2
        [16365] = { "voidwalker", 17751, 3 }, -- Suffering 3
        [16366] = { "voidwalker", 17752, 4 }, -- Suffering 4
        [22183] = { "voidwalker", 27271, 5 }, -- Suffering 5 (TBC)
        [28068] = { "voidwalker", 33701, 6 }, -- Suffering 6 (TBC)
        [16346] = { "voidwalker", 7809, 2 }, -- Torment 2
        [16347] = { "voidwalker", 7810, 3 }, -- Torment 3
        [16348] = { "voidwalker", 7811, 4 }, -- Torment 4
        [16349] = { "voidwalker", 11774, 5 }, -- Torment 5
        [16350] = { "voidwalker", 11775, 6 }, -- Torment 6
        [22182] = { "voidwalker", 27270, 7 }, -- Torment 7 (TBC)
        [16368] = { "succubus", 7815, 2 }, -- Lash of Pain 2
        [16371] = { "succubus", 7816, 3 }, -- Lash of Pain 3
        [16372] = { "succubus", 11778, 4 }, -- Lash of Pain 4
        [16373] = { "succubus", 11779, 5 }, -- Lash of Pain 5
        [16374] = { "succubus", 11780, 6 }, -- Lash of Pain 6
        [22186] = { "succubus", 27274, 7 }, -- Lash of Pain 7 (TBC)
        [16380] = { "succubus", 7870, 1 }, -- Lesser Invisibility
        [16379] = { "succubus", 6358, 1 }, -- Seduction
        [16375] = { "succubus", 6360, 1 }, -- Soothing Kiss 1
        [16376] = { "succubus", 7813, 2 }, -- Soothing Kiss 2
        [16377] = { "succubus", 11784, 3 }, -- Soothing Kiss 3
        [16378] = { "succubus", 11785, 4 }, -- Soothing Kiss 4
        [22187] = { "succubus", 27275, 5 }, -- Soothing Kiss 5 (TBC)
        [16381] = { "felhunter", 19731, 2 }, -- Devour Magic 2
        [16382] = { "felhunter", 19734, 3 }, -- Devour Magic 3
        [16383] = { "felhunter", 19736, 4 }, -- Devour Magic 4
        [22188] = { "felhunter", 27276, 5 }, -- Devour Magic 5 (TBC)
        [22189] = { "felhunter", 27277, 6 }, -- Devour Magic 6 (TBC)
        [16390] = { "felhunter", 19480, 1 }, -- Paranoia
        [16388] = { "felhunter", 19244, 1 }, -- Spell Lock 1
        [16389] = { "felhunter", 19647, 2 }, -- Spell Lock 2
        [16384] = { "felhunter", 19478, 1 }, -- Tainted Blood 1
        [16385] = { "felhunter", 19655, 2 }, -- Tainted Blood 2
        [16386] = { "felhunter", 19656, 3 }, -- Tainted Blood 3
        [16387] = { "felhunter", 19660, 4 }, -- Tainted Blood 4
        [22190] = { "felhunter", 27280, 5 }, -- Tainted Blood 5 (TBC)
        [28071] = { "felguard", 33698, 1 }, -- Anguish 1 (TBC)
        [28072] = { "felguard", 33699, 2 }, -- Anguish 2 (TBC)
        [28073] = { "felguard", 33700, 3 }, -- Anguish 3 (TBC)
        [25469] = { "felguard", 32233, 1 }, -- Avoidance (TBC)
        [23734] = { "felguard", 30213, 1 }, -- Cleave 1 (TBC)
        [23745] = { "felguard", 30219, 2 }, -- Cleave 2 (TBC)
        [23755] = { "felguard", 30223, 3 }, -- Cleave 3 (TBC)
        [25900] = { "felguard", 32850, 1 }, -- Demonic Frenzy (TBC)
        [23711] = { "felguard", 30151, 1 }, -- Intercept 1 (TBC)
        [23730] = { "felguard", 30194, 2 }, -- Intercept 2 (TBC)
        [23731] = { "felguard", 30198, 3 }, -- Intercept 3 (TBC)
    },
}
