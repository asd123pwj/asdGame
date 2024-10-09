using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class RandomGenerator: BaseClass{
    public static System.Random _rand;
    public static int _seed;

    public static int _random_by_prob(float[] probs, Vector3Int offsets, int extra_offset = 0){
        float sum = probs.Sum();
        double target = _nextDouble(sum, offsets, extra_offset);
        for(int i = 0; i < probs.Length; i++){
            target -= probs[i];
            if(target <= 0){
                return i;
            }
        }
        return probs.Length - 1;
    }
    public static int _random_by_prob(float[] probs, float offset, int extra_offset = 0){
        float sum = probs.Sum();
        // float target = _nextDouble(sum, offsets, extra_offset);
        double target = _nextDouble(sum, offset, extra_offset);
        for(int i = 0; i < probs.Length; i++){
            target -= probs[i];
            if(target <= 0){
                return i;
            }
        }
        return probs.Length - 1;
    }


    public static float _range(float min, float max, Vector3 offsets, int extra_offset = 0) => _range(min, max, offsets.x + offsets.y + offsets.z, extra_offset);
    public static float _range(float min, float max, float offset, int extra_offset = 0){
        float random_offset = offset + extra_offset;
        float result = Random.Range(min + random_offset, max + random_offset) - random_offset;
        return result;
    }

    public static int _range(int min, int max, Vector3Int offsets, int extra_offset = 0){
        int random_offset = offsets.x + offsets.y + offsets.z + extra_offset;
        int result = Random.Range(min + random_offset, max + random_offset) - random_offset;
        return result;
    }
    
    public static double _nextDouble(float max, Vector3Int offsets, int extra_offset = 0){
        int random_offset = offsets.x + offsets.y + offsets.z + extra_offset;
        System.Random rand = new(_seed + random_offset + (int)max);
        double result = rand.NextDouble() * max;
        return result;
    }
    public static double _nextDouble(float max, float offset, int extra_offset = 0){
        int random_offset = Mathf.CeilToInt(1000000000 * offset) + extra_offset;
        System.Random rand = new(_seed + random_offset + (int)max);
        double result = rand.NextDouble() * max;
        return result;
    }

    public static int _next(int min, int max, Vector3Int offsets, int extra_offset = 0){
        int random_offset = offsets.x + offsets.y + offsets.z + extra_offset;
        int result = _rand.Next(min + random_offset, max + random_offset) - random_offset;
        return result;
    }
}