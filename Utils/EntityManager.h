//
//  EntityManager.h
//  LienQuanVNMod
//
//  Created by Le Tien Dat on 5/11/26.
//

#import "Vector2.h"
#import "Vector3.h"
#include <vector>

struct enemy_t {
    void *object;
};

class EntityManager {
  public:
    void *myPlayer = NULL;
    std::vector<enemy_t *> *enemies;

    EntityManager() { enemies = new std::vector<enemy_t *>(); }

    bool isEnemyPresent(void *enemyObject) {
        for (std::vector<enemy_t *>::iterator it = enemies->begin();
             it != enemies->end(); it++) {
            if ((*it)->object == enemyObject) {
                return true;
            }
        }
        return false;
    }
    void removeEnemy(enemy_t *enemy) {
        for (int i = 0; i < enemies->size(); i++) {
            if ((*enemies)[i] == enemy) {
                enemies->erase(enemies->begin() + i);
                return;
            }
        }
    }
    void tryAddEnemy(void *enemyObject) {
        if (isEnemyPresent(enemyObject)) {
            return;
        }
        enemy_t *newEnemy = new enemy_t();

        newEnemy->object = enemyObject;

        enemies->push_back(newEnemy);
    }

    void tryAddMyPlayer(void *enemyObject) {
        if (myPlayer == NULL)
            myPlayer = enemyObject;
    }

    void removeEnemyGivenObject(void *enemyObject) {
        for (int i = 0; i < enemies->size(); i++) {
            if ((*enemies)[i]->object == enemyObject) {
                enemies->erase(enemies->begin() + i);
                return;
            }
        }
    }

    void removeAllEnemyGivenObject() {
        myPlayer = NULL;
        for (int i = 0; i < enemies->size(); i++) {
            enemies->erase(enemies->begin() + i);
        }
    }
};
