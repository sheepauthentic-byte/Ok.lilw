//
//  realName.h
//  LienQuanVNMod
//
//  Created by Le Tien Dat on 5/18/26.
//

#pragma once

#include <string>
#include <utility>
#include <vector>

struct HeroInfoEntry {
    int heroID;
    std::string heroName;
    std::string nameReal;
};

static std::vector<HeroInfoEntry> kHeroInfos;

inline void setHeroInfos(std::vector<HeroInfoEntry> heroInfos) {
    kHeroInfos = std::move(heroInfos);
}

inline const HeroInfoEntry *findHeroInfoByID(int heroID) {
    for (const HeroInfoEntry &entry : kHeroInfos) {
        if (entry.heroID == heroID) {
            return &entry;
        }
    }

    static const HeroInfoEntry emptyHeroInfo = {-999, "", ""};
    return &emptyHeroInfo;
}

inline void getNameFromHeroID(std::string &heroName, std::string &nameReal,
                              int heroID) {
    heroName.clear();
    nameReal.clear();

    const HeroInfoEntry *entry = findHeroInfoByID(heroID);
    if (entry != nullptr) {
        heroName = entry->heroName;
        nameReal = entry->nameReal;
    }
}
