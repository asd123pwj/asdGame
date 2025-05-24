public class ObjectAsDrag: ObjectAsBase{
    float original_gravity_scale;
    public ObjectAsDrag(ObjectBase Base): base(Base){}

    public override void _apply(){
        original_gravity_scale = _Base._rb.gravityScale;
        _Base._rb.gravityScale = 1;
    }

    public override void _clear(){
        _Base._rb.gravityScale = original_gravity_scale;
    }
}