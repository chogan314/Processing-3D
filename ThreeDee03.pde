Maxim maxim = new Maxim(this);
Game game;

void setup() {
  size(800, 600, P3D);
  game = new Game();
  game.setScreen(new GameScreen(game, maxim));
}

void draw() {
  game.run();
}


//=====================================================
//====HANDLE INPUT (cannot be delegated to screen)=====
//=====================================================
void keyPressed() {
  if(game.getScreen() instanceof GameScreen) {
    GameScreen thisScreen = (GameScreen) game.getScreen();
    
    if(keyCode == SHIFT) {
      thisScreen.person.running = true;
    }
    switch(key) {
      case 'w': case 'W':
        thisScreen.person.movingForward = true;
        break;
      case 's': case 'S':
        thisScreen.person.movingBackward = true;
        break;
      case 'd': case 'D':
        thisScreen.person.movingRight = true;
        break;
      case 'a': case 'A':
        thisScreen.person.movingLeft = true;
        break;
      case 'r': case 'R':
        for(Star star : thisScreen.stars) {
          star.bounces = 0;
          star.active = false;
          dropTimer = (random(1000) / 1000) * random(4);
          star.accum = 0;
          star.position.set(random(1180) - 50, -3000, (random(1180) - 50) * -1, 100);
          star.accel.set(0, 900, 0);
          star.velocity.y = 0;
        }
        break;
      default:
        break;
    }
  }
}

void keyReleased() {
  if(game.getScreen() instanceof GameScreen) {
    GameScreen thisScreen = (GameScreen) game.getScreen();
    
    if(keyCode == SHIFT) {
      thisScreen.person.running = false;
    }
    switch(key) {
      case 'w': case 'W':
        thisScreen.person.movingForward = false;
        break;
      case 's': case 'S':
        thisScreen.person.movingBackward = false;
        break;
      case 'd': case 'D':
        thisScreen.person.movingRight = false;
        break;
      case 'a': case 'A':
        thisScreen.person.movingLeft = false;
        break;
      default:
        break;
    }
  }
}
public class Camera {
  public PVector position;
  public float yaw, pitch;
  
  public Camera() {
    position = new PVector();
  }
  
  //set yaw and pitch to specific angles
  public void setAngles(float yaw, float pitch) {
    if (pitch < -Math.PI / 2)
      pitch = (float) (-Math.PI / 2);
    if (pitch > Math.PI / 2)
      pitch = (float) (Math.PI / 2);
    this.yaw = yaw;
    this.pitch = pitch;
  }
  
  //increase yaw and pitch by amount
  public void rotate(float yawInc, float pitchInc) {
    this.yaw += yawInc;
    this.pitch += pitchInc;
    if (pitch < -Math.PI / 2)
      pitch = (float) (-Math.PI / 2);
    if (pitch > Math.PI / 2)
      pitch = (float) (Math.PI / 2);
  }
  
  //set camera's rotation matrices -- used when drawing
  public void setMatrices() {
    rotateX(pitch);
    rotateY(yaw);
    translate(position.x, position.y, position.z);
  }
  
  //get direction camera is pointed
  PMatrix3D matrix = new PMatrix3D();
  final float[] inVec = { 0, 0, -1, 1 };
  final float[] outVec = new float[4];
  final PVector direction = new PVector();
  
  public PVector getDirection() {
    matrix.reset();
    matrix.rotateY(yaw);
    matrix.mult(inVec, outVec);
    direction.set(outVec[0], outVec[1], -outVec[2]);
    return direction;
  }
  
  public PVector getPerpendicular() {
    matrix.reset();
    matrix.rotate(yaw + PI / 2, 0, 1, 0);
    matrix.mult(inVec, outVec);
    direction.set(outVec[0], outVec[1], -outVec[2]);
    return direction;
  }
}
public abstract class DynamicGameObject3D extends GameObject3D {
  public final PVector velocity;
  public final PVector accel;
  
  public DynamicGameObject3D(float x, float y, float z, float radius) {
    super(x, y, z, radius);
    velocity = new PVector();
    accel = new PVector();
  }
}
public class Game {
  //delegates tasks to active screen
  //allows for easy transition between screens
  
  private Screen screen;
  private long startTime;
  
  public Game() {
    startTime = millis();
  }
  
  //main game loop
  public void run() {
    float delta = (millis() - startTime) / 1000.0f;
    startTime = millis();
    
    update(delta);
    present();
  }
  
  private void update(float delta) {
    if(screen != null) {
      screen.update(delta);
    }
  }
  
  private void present() {
    if(screen != null) {
      screen.present();
    }
  }
  
  public void setScreen(Screen screen) {
    this.screen = screen;
  }
  
  public Screen getScreen() {
    return screen;
  } 
}
public abstract class GameObject3D {
  public final PVector position;
  public final Sphere bounds;
  
  public GameObject3D(float x, float y, float z, float radius) {
    this.position = new PVector(x, y, z);
    this.bounds = new Sphere(x, y, z, radius);
  }
}
public class GameScreen extends Screen {
  private static final int NUMBER_OF_STARS = 100;
  
  public Person person;
  public Camera cam;
  ArrayList<Star> stars;
  
  AudioPlayer footstepsSlow, footstepsFast;
  ArrayList<AudioPlayer> bounceSounds;
  
  public GameScreen(Game game, Maxim maxim) {
    super(game);
    this.maxim = maxim;
    
    person = new Person(-600, 7.5 + 110, 600, 7.5);
    cam = new Camera();
    cam.position.set(person.position.x, person.position.y + person.height, person.position.z);
    
    stars = new ArrayList<Star>();
    for(int i = 0; i < NUMBER_OF_STARS; i++) {
      Star star = new Star(random(1180) - 50, -3000, (random(1180) - 50) * -1, 100);
      star.accel.set(0, 900, 0);
      stars.add(star);
    }
    
    footstepsSlow = maxim.loadFile("footsteps_normal.mp3");
    footstepsSlow.setLooping(true);
    
    footstepsFast = maxim.loadFile("footsteps_fast.mp3");
    footstepsFast.setLooping(true);
  
    bounceSounds = new ArrayList<AudioPlayer>(); 
    for(int i = 0; i < NUMBER_OF_STARS; i++) {
      bounceSounds.add(maxim.loadFile("bounce.wav"));
    }
  }
  
  public void update(float delta) {
    if((abs(person.velocity.x) > 0 || abs(person.velocity.z) > 0) && !person.running) {
      footstepsSlow.play();
    } else {
      footstepsSlow.stop();
    }
    
    if((abs(person.velocity.x) > 0 || abs(person.velocity.z) > 0) && person.running) {
      footstepsFast.play();
    } else {
      footstepsFast.stop();
    }
    
    float deltaX = 0;
    float deltaY = 0;
    
    if(mouseX - width / 2 > 40) {
      deltaX = (float)(mouseX - (width / 2 + 20)) / (float)(width / 2 - 20);
    } else if (mouseX - width / 2 < -40) {
      deltaX = (float)(mouseX - (width / 2 - 20)) / (float)(width / 2 - 20);
    }
    
    if(mouseY - height / 2 > 30) {
      deltaY = (float)(mouseY - (height / 2 + 15)) / (float)(width / 2 - 15);
    } else if(mouseY - height / 2 < - 30) {
      deltaY = (float)(mouseY - (height / 2 - 15)) / (float)(width / 2 - 15);
    }
    
    person.rotate(deltaX * delta * 2, -deltaY * delta * 2);    
    cam.setAngles(person.lookYaw, person.lookPitch);
    
    person.update(delta);
    if(person.position.x < -1110) {
      person.position.x = -1110;
    } else if (person.position.x > 30) {
      person.position.x = 30;
    }
    
    if(person.position.z < -30) {
      person.position.z = -30;
    } else if (person.position.z > 1110) {
      person.position.z = 1110;
    }    
    
    cam.position.x = person.position.x;
    cam.position.y = person.position.y + person.height;
    cam.position.z = person.position.z;
    
    for(int i = 0; i < NUMBER_OF_STARS; i++) {
      Star star = stars.get(i);
      star.update(delta);
      if(star.velocity.y > 0) {
        checkStarCollision(i);
      }
    }
  }
  
  //check collision -- bounce, play sound
  private void checkStarCollision(int index) {
    Star star = stars.get(index);
    if(star.position.y > -60) {
      star.position.y = -60;
      star.velocity.y *= -0.5;
      star.bounces++;
      if(star.bounces >= star.maxBounces) {
        star.velocity.y = 0;
        star.accel.y = 0;
      } else {
        AudioPlayer sound = bounceSounds.get(index);
        sound.stop();
        sound.cue(0);
        
        sound.speed(max(abs(star.velocity.y) / 1000, 0.4));
        sound.volume(min(1, (star.velocity.y / 500) * (100 / PVector.dist(star.position, person.position))));
        sound.play();
      }
    }
  }
  
  public void present() {
    camera(0, 0, 0, 0, 0, -1, 0, 1, 0);
    background(0);
    
    lights();
    
    cam.setMatrices();    
    
    noStroke();
    fill(100, 149, 237);
    sphereDetail(4);
    for(Star star : stars) {
      if(star.active) {
        pushMatrix();
        translate(star.position.x, star.position.y, star.position.z);
        sphere(10);
        popMatrix();
      }
    }
    
    fill(248, 221, 92);
    for(int z = 0; z < 10; z++) {
      for(int x = 0; x < 10; x++) {
        pushMatrix();
        translate(x * 120, 0, z * -120);
        box(100);
        popMatrix();
      }
    }
  }
}
public class Person extends DynamicGameObject3D {
  public boolean movingForward = false;
  public boolean movingBackward = false;
  public boolean movingRight = false;
  public boolean movingLeft = false;
  public boolean running = false;
  public boolean falling = false;
  
  public float lookPitch, lookYaw;
  public float height;
  
  public Person(float x, float y, float z, float radius) {
    super(x, y, z, radius);
    height = radius * 2;
  }
  
  public void setAngles(float yaw, float pitch) {
    if (pitch < -Math.PI / 2)
      pitch = (float) (-Math.PI / 2);
    if (pitch > Math.PI / 2)
      pitch = (float) (Math.PI / 2);
    this.lookYaw = yaw;
    this.lookPitch = pitch;
  }
  
  public void rotate(float yawInc, float pitchInc) {
    this.lookYaw += yawInc;
    this.lookPitch += pitchInc;
    if (lookPitch < -Math.PI / 2)
      lookPitch = (float) (-Math.PI / 2);
    if (lookPitch > Math.PI / 2)
      lookPitch = (float) (Math.PI / 2);
  }
  
  PMatrix3D matrix = new PMatrix3D();
  final float[] inVec = { 0, 0, -1, 1 };
  final float[] outVec = new float[4];
  final PVector direction = new PVector();
  
  public PVector getDirection() {
    matrix.reset();
    matrix.rotate(lookYaw, 0, 1, 0);
    
    matrix.get().mult(inVec, outVec);
    direction.set(outVec[0], outVec[1], -outVec[2]);
    
    return direction;
  }
  
  public PVector getPerpendicular() {
    matrix.reset();
    matrix.rotate(lookYaw - (float)Math.PI / 2, 0, 1, 0);
    
    matrix.get().mult(inVec, outVec);
    direction.set(outVec[0], outVec[1], -outVec[2]);
    
    return direction;
  }
  
  public void update(float delta) {
    calcMove();
    position.add(PVector.mult(velocity, delta));
    bounds.center.set(position);
  }
  
  private void calcMove() {
    velocity.x = 0;
    velocity.z = 0;
    if(movingForward) {
      velocity.add(getDirection());
    }
    if(movingBackward) {
      velocity.add(PVector.mult(getDirection(), -1));
    }
    if(movingLeft) {
      velocity.add(getPerpendicular());
    }
    if(movingRight) {
      velocity.add(PVector.mult(getPerpendicular(), -1));
    }
    
    float mag = (float) Math.sqrt(velocity.x * velocity.x + velocity.z * velocity.z);
    if (mag != 0 && mag != 1) {
        velocity.x /= mag;
        velocity.z /= mag;
     }    

    velocity.x *= running ? 200 : 100;
    velocity.z *= running ? 200 : 100;
  }
}
public abstract class Screen {
  protected Game game;
  
  public Screen(Game game) {
    this.game = game;
  }
  
  public abstract void update(float delta);
  public abstract void present();
}
public class Sphere {
  public final PVector center = new PVector();
  public float radius;
  
  public Sphere(float x, float y, float z, float radius) {
    this.center.set(x, y, z);
    this.radius = radius;
  }
}
public class Star extends DynamicGameObject3D {
  public float dropTimer;
  public float accum;
  public boolean active = false;
  public float maxBounces = 6;
  public float bounces = 0;
  
  public Star(float x, float y, float z, float radius) {
    super(x, y, z, radius);
    dropTimer = (random(1000) / 1000) * random(4);
  }
  
  public void update(float delta) {
    accum += delta;
    if(accum > dropTimer) {
      active = true;
      velocity.add(PVector.mult(accel, delta));
      position.add(PVector.mult(velocity, delta));
    }
  }
}

