//
//  HeroTextureData.mm
//  LienQuanVNMod
//
//  Created by Le Tien Dat on 5/29/26.
//

#import "HeroTextureData.h"
#import "image.mm"

#include <stdlib.h>
#include <string.h>

const HeroTextureData *HeroTextureDataItems(NSUInteger *count) {
    static HeroTextureData *items = NULL;
    static NSUInteger itemCount = 0;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
      const HeroTextureData initialItems[] = {
          {@"", null_data},
          {@"airi", airi_data},
          {@"aleister", aleister_data},
          {@"alice", alice_data},
          {@"allain", allain_data},
          {@"amily", amily_data},
          {@"annette", annette_data},
          {@"aoi", aoi_data},
          {@"arduin", arduin_data},
          {@"athur", arthur_data},
          {@"arum", arum_data},
          {@"astrid", astrid_data},
          {@"ata", ata_data},
          {@"aya", aya_data},
          {@"azzenka", azzenka_data},
          {@"baldum", baldum_data},
          {@"bijan", bijan_data},
          {@"bonnie", bonnie_data},
          {@"bright", bright_data},
          {@"butterfly", butterfly_data},
          {@"capheny", capheny_data},
          {@"celica", celica_data},
          {@"charlotter", charlotter_data},
          {@"chaugnar", chaugnar_data},
          {@"cresht", cresht_data},
          {@"darcy", darcy_data},
          {@"dextra", dextra_data},
          {@"dieuthuyen", dieuthuyen_data},
          {@"dirak", dirak_data},
          {@"dolia", dolia_data},
          {@"elandorr", elandorr_data},
          {@"elsu", elsu_data},
          {@"enzo", enzo_data},
          {@"erin", erin_data},
          {@"errol", errol_data},
          {@"fennik", fennik_data},
          {@"florentino", florentino_data},
          {@"gildur", gildur_data},
          {@"grakk", grakk_data},
          {@"hayate", hayate_data},
          {@"helen", helen_data},
          {@"iggy", iggy_data},
          {@"ignis", ignis_data},
          {@"ilumia", ilumia_data},
          {@"ishar", ishar_data},
          {@"jinna", jinna_data},
          {@"kahlii", kahlii_data},
          {@"kaine", kaine_data},
          {@"keera", kerra_data},
          {@"kilgroth", kilgroth_data},
          {@"kriknak", kriknak_data},
          {@"krixi", krixi_data},
          {@"krizzix", krizzix_data},
          {@"lauriel", lauriel_data},
          {@"laville", laville_data},
          {@"liliana", liliana_data},
          {@"lindis", lindis_data},
          {@"lorion", lorion_data},
          {@"lubo", lubo_data},
          {@"lumburr", lumburr_data},
          {@"maloch", maloch_data},
          {@"marja", marja_data},
          {@"max", max_data},
          {@"mganga", mganga_data},
          {@"mina", mina_data},
          {@"ming", ming_data},
          {@"moren", moren_data},
          {@"murad", murad_data},
          {@"nakroth", nakroth_data},
          {@"natalya", natalya_data},
          {@"ngokhong", ngokhong_data},
          {@"ormarr", omar_data},
          {@"omega", omega_data},
          {@"omen", omen_data},
          {@"paine", pain_data},
          {@"preyta", preyta_data},
          {@"qi", qi_data},
          {@"quillen", quilen_data},
          {@"raz", raz_data},
          {@"richter", richter_data},
          {@"rouie", rouie_data},
          {@"rourke", rouke_data},
          {@"roxie", roxie_data},
          {@"ryoma", ryoma_data},
          {@"sephera", sephera_data},
          {@"sinestrea", sinestrea_data},
          {@"skud", skud_data},
          {@"slimz", slimz_data},
          {@"stuart", Stuart_data},
          {@"supperman", superman_data},
          {@"tachi", tachi_data},
          {@"tarra", tara_data},
          {@"teemee", teemee_data},
          {@"telannas", telannas_data},
          {@"terri", terri_data},
          {@"thane", thane_data},
          {@"theflash", theflash_data},
          {@"thorne", thorne_data},
          {@"toro", toro_data},
          {@"trieuvan", trieuvan_data},
          {@"tulen", tulen_data},
          {@"valhein", valhein_data},
          {@"veres", veres_data},
          {@"veera", verra_data},
          {@"violet", violet_data},
          {@"volkath", volkat_data},
          {@"wisp", wips_data},
          {@"wiro", wiro_data},
          {@"wonderwoman", wonderwoman_data},
          {@"xenniel", xeniel_data},
          {@"yan", yan_data},
          {@"ybneth", ybneth_data},
          {@"yenna", yena_data},
          {@"yorn", yorn_data},
          {@"yue", yue_data},
          {@"zata", zata_data},
          {@"zephys", zephys_data},
          {@"zill", zill_data},
          {@"zip", zip_data},
          {@"zuka", zuka_data},
          {@"biron", biron_data},
          {@"heino", heino_data},
          {@"dyadia", dyadia_data},
          {@"flowborn", flowborn_data},
          {@"edras", edras_data},
          {@"goverra", goverra_data},
          {@"boltbaron", boltbaron_data},
          {@"billow", billow_data},
      };

      itemCount = sizeof(initialItems) / sizeof(initialItems[0]);
      items = (HeroTextureData *)calloc(itemCount, sizeof(HeroTextureData));
      memcpy(items, initialItems, sizeof(initialItems));
    });

    if (count != NULL) {
        *count = itemCount;
    }

    return items;
}
