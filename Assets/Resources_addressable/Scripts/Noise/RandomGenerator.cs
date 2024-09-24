using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class RandomGenerator{

    public static int _random_by_prob(float[] probs, Vector3Int offsets, int extra_offset = 0){
        float sum = probs.Sum();
        int random_offset = offsets.x + offsets.y + offsets.z + extra_offset;
        float target = Random.Range(random_offset, sum + random_offset) - random_offset;
        for(int i = 0; i < probs.Length; i++){
            target -= probs[i];
            if(target <= 0){
                return i;
            }
        }
        return probs.Length - 1;
    }

    public static float _range(float min, float max, Vector3 offsets, int extra_offset = 0){
        float random_offset = offsets.x + offsets.y + offsets.z + extra_offset;
        float result = Random.Range(min + random_offset, max + random_offset) - random_offset;
        return result;
    }
    
    public static int _range(int min, int max, Vector3Int offsets, int extra_offset = 0){
        int random_offset = offsets.x + offsets.y + offsets.z + extra_offset;
        int result = Random.Range(min + random_offset, max + random_offset) - random_offset;
        return result;
    }
}