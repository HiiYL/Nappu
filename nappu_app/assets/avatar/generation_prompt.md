# Nappu Avatar Image Generation Prompt (GPT Image 2)

## Base Character Description

Nappu is a cute, round, fluffy white sheep character — the mascot of a sleep-tracking app for teens. Style: **kawaii / chibi**, soft pastel aesthetic, simple flat illustration with subtle shading. Large expressive eyes, small rounded body, tiny legs, fluffy wool texture. Think Molang / Pusheen level of simplicity and cuteness.

Consistent across all images:
- Square canvas (1024×1024)
- Transparent or themed background
- Centered character
- Soft lighting, no harsh shadows
- Clean vector-style illustration

---

## Moods (4 expressions)

Generate each outfit/background combo in **one mood** (happy as default). Generate the remaining moods separately as base variations.

| Mood | Expression |
|------|-----------|
| **happy** | Soft smile, open eyes, cheerful |
| **energized** | Wide sparkling eyes, big grin, slight bounce pose |
| **tired** | Half-closed droopy eyes, small neutral mouth, slight slouch |
| **sleepy** | Eyes nearly closed, small "zzz" floating above, curled-up/relaxed pose |

---

## Hats (8 items)

| # | Name | Visual Description |
|---|------|--------------------|
| 1 | **Top Hat** | Classic black top hat perched on head |
| 2 | **Cap** | Casual baseball cap, worn slightly tilted |
| 3 | **Crown** | Small golden crown with jewels |
| 4 | **Flower** | Single pink cherry blossom tucked behind ear |
| 5 | **Helmet** | Small green army/adventure helmet |
| 6 | **Grad Cap** | Black graduation mortarboard with tassel |
| 7 | **Bear Ear** | Cute bear-ear headband (brown) |
| 8 | **Halo** | Glowing golden halo floating above head |

---

## Outfits (4 items)

| # | Name | Visual Description |
|---|------|--------------------|
| 1 | **Pajamas** | Cozy light blue pajama onesie with tiny star pattern |
| 2 | **Sweater** | Oversized warm knit sweater (cream/beige) |
| 3 | **Cape** | Small superhero cape (purple/blue) flowing behind |
| 4 | **Scarf** | Knitted scarf (red/orange) wrapped around neck |

---

## Accessories (4 items — held or placed next to character)

| # | Name | Visual Description |
|---|------|--------------------|
| 1 | **Pillow** | Soft white pillow being hugged or next to Nappu |
| 2 | **Blanket** | Cozy blanket draped over or wrapped around Nappu |
| 3 | **Teddy** | Small brown teddy bear held in arms |
| 4 | **Moon Lamp** | Glowing crescent moon lamp placed beside Nappu |

---

## Room Themes / Backgrounds (3)

| # | Name | Visual Description |
|---|------|--------------------|
| 1 | **Night Sky** | Deep navy/indigo sky with twinkling stars, crescent moon, soft gradient |
| 2 | **Sakura** | Soft pink/mauve background with falling cherry blossom petals |
| 3 | **Mountain** | Dark green forest/mountain scene, pine trees, peaceful nature |

---

## Generation Matrix

### Phase 1 — Base Nappu (no accessories, default pajamas + top hat)
Generate 4 images (one per mood) on Night Sky background:

```
1. Nappu — happy, Pajamas, Top Hat, Night Sky
2. Nappu — energized, Pajamas, Top Hat, Night Sky
3. Nappu — tired, Pajamas, Top Hat, Night Sky
4. Nappu — sleepy, Pajamas, Top Hat, Night Sky
```

### Phase 2 — All Hats (happy mood, Pajamas, Night Sky, no accessory)
Generate 7 images (skip Top Hat, already in Phase 1):

```
5.  Nappu — happy, Pajamas, Cap, Night Sky
6.  Nappu — happy, Pajamas, Crown, Night Sky
7.  Nappu — happy, Pajamas, Flower, Night Sky
8.  Nappu — happy, Pajamas, Helmet, Night Sky
9.  Nappu — happy, Pajamas, Grad Cap, Night Sky
10. Nappu — happy, Pajamas, Bear Ear, Night Sky
11. Nappu — happy, Pajamas, Halo, Night Sky
```

### Phase 3 — All Outfits (happy mood, Top Hat, Night Sky, no accessory)
Generate 3 images (skip Pajamas, already in Phase 1):

```
12. Nappu — happy, Sweater, Top Hat, Night Sky
13. Nappu — happy, Cape, Top Hat, Night Sky
14. Nappu — happy, Scarf, Top Hat, Night Sky
```

### Phase 4 — All Accessories (happy mood, Pajamas, Top Hat, Night Sky)
Generate 4 images:

```
15. Nappu — happy, Pajamas, Top Hat, Night Sky, holding Pillow
16. Nappu — happy, Pajamas, Top Hat, Night Sky, with Blanket
17. Nappu — happy, Pajamas, Top Hat, Night Sky, holding Teddy
18. Nappu — happy, Pajamas, Top Hat, Night Sky, with Moon Lamp
```

### Phase 5 — Room Themes (happy mood, Pajamas, Top Hat, no accessory)
Generate 2 images (skip Night Sky, already in Phase 1):

```
19. Nappu — happy, Pajamas, Top Hat, Sakura
20. Nappu — happy, Pajamas, Top Hat, Mountain
```

---

**Total: 20 images** covering all unique variations.

---

## Prompt Template

Use this template for each image, filling in the bracketed fields:

```
A cute kawaii chibi illustration of Nappu, a small round fluffy white sheep character with [MOOD_EXPRESSION]. Nappu is wearing [OUTFIT_DESCRIPTION] and [HAT_DESCRIPTION] on its head. [ACCESSORY_SENTENCE] The background is [BACKGROUND_DESCRIPTION]. Soft pastel color palette, flat illustration style with subtle shading, centered composition, clean lines, adorable and cozy aesthetic. Square format, transparent-friendly.
```

### Example filled prompt:

```
A cute kawaii chibi illustration of Nappu, a small round fluffy white sheep character with half-closed droopy eyes and a small neutral mouth, looking tired. Nappu is wearing a cozy light blue pajama onesie with tiny star patterns and a classic black top hat perched on its head. Nappu is hugging a soft white pillow. The background is a deep navy indigo night sky with twinkling stars and a crescent moon. Soft pastel color palette, flat illustration style with subtle shading, centered composition, clean lines, adorable and cozy aesthetic. Square format, transparent-friendly.
```

---

## File Naming Convention

```
nappu_[mood]_[outfit]_[hat]_[accessory]_[background].png
```

Examples:
- `nappu_happy_pajamas_tophat_none_nightsky.png`
- `nappu_sleepy_pajamas_tophat_pillow_nightsky.png`
- `nappu_happy_sweater_crown_teddy_sakura.png`

---

## Notes for Consistency
- Keep Nappu's proportions identical across all images
- The sheep should always be recognizably the same character
- Hats sit on top of the wool/head
- Outfits wrap around the body
- Accessories are held or placed beside (not worn)
- Background should not overpower the character — Nappu should always be the focal point
