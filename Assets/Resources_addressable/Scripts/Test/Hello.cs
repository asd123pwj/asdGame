using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Hello : MonoBehaviour
{
    public string hello_public = "hello public";
    // Start is called before the first frame update
    void Start()
    {
        string hello_local = "hello local";
        hello_public = "hello public 22";
        print("Hello in 2023/2/4.");
        print(hello_public);
        print(hello_local);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
