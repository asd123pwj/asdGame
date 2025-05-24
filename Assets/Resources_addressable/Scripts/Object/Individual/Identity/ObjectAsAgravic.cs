public class ObjectAsAgravic: ObjectAsBase{
    float original_gravity_scale;

    public ObjectAsAgravic(ObjectBase Base): base(Base){}

    public override void _apply(){
        original_gravity_scale = _Base._rb.gravityScale;
        _Base._rb.gravityScale = 0;
    }

    public override void _clear(){
        _Base._rb.gravityScale = original_gravity_scale;
    }
}