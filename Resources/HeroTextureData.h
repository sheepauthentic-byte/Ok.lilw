//
//  HeroTextureData.h
//  LienQuanVNMod
//
//  Created by Le Tien Dat on 5/29/26.
//

#ifndef HERO_TEXTURE_DATA_H
#define HERO_TEXTURE_DATA_H

#import <Foundation/Foundation.h>

typedef struct {
    __unsafe_unretained NSString *heroName;
    __unsafe_unretained NSString *base64Data;
} HeroTextureData;

const HeroTextureData *HeroTextureDataItems(NSUInteger *count);

#endif
