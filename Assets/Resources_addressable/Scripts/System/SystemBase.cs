using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class SystemBase : MonoBehaviour{
    public int seed_random = 10636;
    // Start is called before the first frame update
    void Start(){
        Random.InitState(seed_random);
    }

    // Update is called once per frame
    void Update(){
        
    }
}
