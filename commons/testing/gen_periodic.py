import json

COLORS = {
    "alkali": "#EF5350",
    "alkaline": "#FF7043",
    "transition": "#FFA726",
    "post_transition": "#66BB6A",
    "metalloid": "#26A69A",
    "nonmetal": "#42A5F5",
    "halogen": "#5C6BC0",
    "noble": "#AB47BC",
    "lanthanide": "#EC407A",
    "actinide": "#F48FB1",
}

ALL = [
    (1,"H","Hydrogen","nonmetal",1.008),
    (2,"He","Helium","noble",4.003),
    (3,"Li","Lithium","alkali",6.941),
    (4,"Be","Beryllium","alkaline",9.012),
    (5,"B","Boron","metalloid",10.81),
    (6,"C","Carbon","nonmetal",12.01),
    (7,"N","Nitrogen","nonmetal",14.01),
    (8,"O","Oxygen","nonmetal",16.00),
    (9,"F","Fluorine","halogen",19.00),
    (10,"Ne","Neon","noble",20.18),
    (11,"Na","Sodium","alkali",22.99),
    (12,"Mg","Magnesium","alkaline",24.31),
    (13,"Al","Aluminium","post_transition",26.98),
    (14,"Si","Silicon","metalloid",28.09),
    (15,"P","Phosphorus","nonmetal",30.97),
    (16,"S","Sulfur","nonmetal",32.07),
    (17,"Cl","Chlorine","halogen",35.45),
    (18,"Ar","Argon","noble",39.95),
    (19,"K","Potassium","alkali",39.10),
    (20,"Ca","Calcium","alkaline",40.08),
    (21,"Sc","Scandium","transition",44.96),
    (22,"Ti","Titanium","transition",47.87),
    (23,"V","Vanadium","transition",50.94),
    (24,"Cr","Chromium","transition",52.00),
    (25,"Mn","Manganese","transition",54.94),
    (26,"Fe","Iron","transition",55.85),
    (27,"Co","Cobalt","transition",58.93),
    (28,"Ni","Nickel","transition",58.69),
    (29,"Cu","Copper","transition",63.55),
    (30,"Zn","Zinc","transition",65.38),
    (31,"Ga","Gallium","post_transition",69.72),
    (32,"Ge","Germanium","metalloid",72.63),
    (33,"As","Arsenic","metalloid",74.92),
    (34,"Se","Selenium","nonmetal",78.97),
    (35,"Br","Bromine","halogen",79.90),
    (36,"Kr","Krypton","noble",83.80),
    (37,"Rb","Rubidium","alkali",85.47),
    (38,"Sr","Strontium","alkaline",87.62),
    (39,"Y","Yttrium","transition",88.91),
    (40,"Zr","Zirconium","transition",91.22),
    (41,"Nb","Niobium","transition",92.91),
    (42,"Mo","Molybdenum","transition",95.95),
    (43,"Tc","Technetium","transition",98.0),
    (44,"Ru","Ruthenium","transition",101.07),
    (45,"Rh","Rhodium","transition",102.91),
    (46,"Pd","Palladium","transition",106.42),
    (47,"Ag","Silver","transition",107.87),
    (48,"Cd","Cadmium","transition",112.41),
    (49,"In","Indium","post_transition",114.82),
    (50,"Sn","Tin","post_transition",118.71),
    (51,"Sb","Antimony","metalloid",121.76),
    (52,"Te","Tellurium","metalloid",127.60),
    (53,"I","Iodine","halogen",126.90),
    (54,"Xe","Xenon","noble",131.29),
    (55,"Cs","Caesium","alkali",132.91),
    (56,"Ba","Barium","alkaline",137.33),
    (57,"La","Lanthanum","lanthanide",138.91),
    (58,"Ce","Cerium","lanthanide",140.12),
    (59,"Pr","Praseodymium","lanthanide",140.91),
    (60,"Nd","Neodymium","lanthanide",144.24),
    (61,"Pm","Promethium","lanthanide",145.0),
    (62,"Sm","Samarium","lanthanide",150.36),
    (63,"Eu","Europium","lanthanide",151.96),
    (64,"Gd","Gadolinium","lanthanide",157.25),
    (65,"Tb","Terbium","lanthanide",158.93),
    (66,"Dy","Dysprosium","lanthanide",162.50),
    (67,"Ho","Holmium","lanthanide",164.93),
    (68,"Er","Erbium","lanthanide",167.26),
    (69,"Tm","Thulium","lanthanide",168.93),
    (70,"Yb","Ytterbium","lanthanide",173.05),
    (71,"Lu","Lutetium","lanthanide",174.97),
    (72,"Hf","Hafnium","transition",178.49),
    (73,"Ta","Tantalum","transition",180.95),
    (74,"W","Tungsten","transition",183.84),
    (75,"Re","Rhenium","transition",186.21),
    (76,"Os","Osmium","transition",190.23),
    (77,"Ir","Iridium","transition",192.22),
    (78,"Pt","Platinum","transition",195.08),
    (79,"Au","Gold","transition",196.97),
    (80,"Hg","Mercury","transition",200.59),
    (81,"Tl","Thallium","post_transition",204.38),
    (82,"Pb","Lead","post_transition",207.2),
    (83,"Bi","Bismuth","post_transition",208.98),
    (84,"Po","Polonium","post_transition",209.0),
    (85,"At","Astatine","halogen",210.0),
    (86,"Rn","Radon","noble",222.0),
    (87,"Fr","Francium","alkali",223.0),
    (88,"Ra","Radium","alkaline",226.0),
    (89,"Ac","Actinium","actinide",227.0),
    (90,"Th","Thorium","actinide",232.04),
    (91,"Pa","Protactinium","actinide",231.04),
    (92,"U","Uranium","actinide",238.03),
    (93,"Np","Neptunium","actinide",237.0),
    (94,"Pu","Plutonium","actinide",244.0),
    (95,"Am","Americium","actinide",243.0),
    (96,"Cm","Curium","actinide",247.0),
    (97,"Bk","Berkelium","actinide",247.0),
    (98,"Cf","Californium","actinide",251.0),
    (99,"Es","Einsteinium","actinide",252.0),
    (100,"Fm","Fermium","actinide",257.0),
    (101,"Md","Mendelevium","actinide",258.0),
    (102,"No","Nobelium","actinide",259.0),
    (103,"Lr","Lawrencium","actinide",266.0),
    (104,"Rf","Rutherfordium","transition",267.0),
    (105,"Db","Dubnium","transition",268.0),
    (106,"Sg","Seaborgium","transition",269.0),
    (107,"Bh","Bohrium","transition",270.0),
    (108,"Hs","Hassium","transition",269.0),
    (109,"Mt","Meitnerium","transition",278.0),
    (110,"Ds","Darmstadtium","transition",281.0),
    (111,"Rg","Roentgenium","transition",282.0),
    (112,"Cn","Copernicium","transition",285.0),
    (113,"Nh","Nihonium","post_transition",286.0),
    (114,"Fl","Flerovium","post_transition",289.0),
    (115,"Mc","Moscovium","post_transition",290.0),
    (116,"Lv","Livermorium","post_transition",293.0),
    (117,"Ts","Tennessine","halogen",294.0),
    (118,"Og","Oganesson","noble",294.0),
]

POS = {}
POS[1] = (0, 0); POS[2] = (17, 0)
for i, z in enumerate(range(3, 5)): POS[z] = (i, 1)
for i, z in enumerate(range(5, 11)): POS[z] = (12 + i, 1)
for i, z in enumerate(range(11, 13)): POS[z] = (i, 2)
for i, z in enumerate(range(13, 19)): POS[z] = (12 + i, 2)
for i, z in enumerate(range(19, 21)): POS[z] = (i, 3)
for i, z in enumerate(range(21, 31)): POS[z] = (2 + i, 3)
for i, z in enumerate(range(31, 37)): POS[z] = (12 + i, 3)
for i, z in enumerate(range(37, 39)): POS[z] = (i, 4)
for i, z in enumerate(range(39, 49)): POS[z] = (2 + i, 4)
for i, z in enumerate(range(49, 55)): POS[z] = (12 + i, 4)
POS[55] = (0, 5); POS[56] = (1, 5)
POS[57] = (2, 5)
for i, z in enumerate(range(72, 81)): POS[z] = (3 + i, 5)
for i, z in enumerate(range(81, 87)): POS[z] = (12 + i, 5)
POS[87] = (0, 6); POS[88] = (1, 6)
POS[89] = (2, 6)
for i, z in enumerate(range(104, 113)): POS[z] = (3 + i, 6)
for i, z in enumerate(range(113, 119)): POS[z] = (12 + i, 6)
for i, z in enumerate(range(58, 72)): POS[z] = (3 + i, 8)
for i, z in enumerate(range(90, 104)): POS[z] = (3 + i, 9)

elements = []
for z, sym, name, cat, mass in ALL:
    elements.append({
        "id": "el_" + sym,
        "name": name,
        "category": cat,
        "size": [1, 1],
        "icon": sym,
        "description": str(z) + " - " + name,
        "atomic_number": z,
        "symbol": sym,
        "atomic_mass": mass,
        "group_color": COLORS[cat],
    })

placements = []
for z, sym, name, cat, mass in ALL:
    if z in POS:
        col, row = POS[z]
        placements.append({
            "element": "el_" + sym,
            "position": [col, row],
            "rotation": 0,
        })

placements.sort(key=lambda p: (p["position"][1], p["position"][0]))

# Build the full JSON
existing_presets_file = "tools/grid_editor/subsets/periodic_table.json"
with open(existing_presets_file, "r", encoding="utf-8") as f:
    existing = json.load(f)

# Replace elements
existing["elements"] = elements

# Replace the full_table_mini preset with the complete one
for i, p in enumerate(existing["presets"]):
    if p["id"] == "full_table_mini":
        existing["presets"][i] = {
            "id": "full_table",
            "name": "Full Periodic Table",
            "description": "Complete periodic table — all 118 elements in standard layout with lanthanide and actinide rows.",
            "grid_size": [18, 10],
            "placements": placements,
        }

with open(existing_presets_file, "w", encoding="utf-8") as f:
    json.dump(existing, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("Done! " + str(len(elements)) + " elements, " + str(len(placements)) + " placements in full table")

# Verify
syms = set(e["id"] for e in elements)
placed = set(p["element"] for p in placements)
if syms == placed:
    print("All 118 elements placed.")
else:
    print("Missing: " + str(syms - placed))
