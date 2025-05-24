using UnityEngine;

public class ObjectContactGround: ObjectContactBase{
    public ObjectContactGround(ObjectBase Base): base(Base){
    }

    public override void OnCollisionEnter2D(Collision2D col){
        Debug.Log("Ground Contact");
    }
}