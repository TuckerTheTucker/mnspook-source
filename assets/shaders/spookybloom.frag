// its just the vhs shader but removed most of the code to just contain bloom

#pragma header
#define PI 3.14159265

uniform float time;

vec3 tex2D(sampler2D _tex,vec2 _p)
{
    vec3 col=texture(_tex,_p).xyz;
    if(.5<abs(_p.x-.5)){
        col=vec3(.1);
    }
    return col;
}

float hash(vec2 _v)
{
    return fract(sin(dot(_v,vec2(89.44,19.36)))*22189.22);
}

float iHash(vec2 _v,vec2 _r)
{
    float h00=hash(vec2(floor(_v*_r+vec2(0.,0.))/_r));
    float h10=hash(vec2(floor(_v*_r+vec2(1.,0.))/_r));
    float h01=hash(vec2(floor(_v*_r+vec2(0.,1.))/_r));
    float h11=hash(vec2(floor(_v*_r+vec2(1.,1.))/_r));
    vec2 ip=vec2(smoothstep(vec2(0.,0.),vec2(1.,1.),mod(_v*_r,1.)));
    return(h00*(1.-ip.x)+h10*ip.x)*(1.-ip.y)+(h01*(1.-ip.x)+h11*ip.x)*ip.y;
}

float noise(vec2 _v)
{
    float sum=0.;
    for(int i=1;i<9;i++)
    {
        sum+=iHash(_v+vec2(i),vec2(2.*pow(2.,float(i))))/pow(2.,float(i));
    }
    return sum;
}

void main()
{
    vec2 uv=openfl_TextureCoordv;
    vec2 uvn=uv;
    vec3 col=vec3(0.);
    
    col=tex2D(bitmap,uvn);

    // bloom
    for(float x=-4.;x<2.5;x+=1.){
        col.xyz+=vec3(
            tex2D(bitmap,uvn+vec2(x-0.,0.)*7E-3).x,
            tex2D(bitmap,uvn+vec2(x-2.,0.)*7E-3).y,
            tex2D(bitmap,uvn+vec2(x-4.,0.)*7E-3).z
        )*.1;
    }
    col*=.8;
    
    gl_FragColor=vec4(col,1.);
}