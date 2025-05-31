# Editeur de sprite pour Sanyo PCH 25
import pygame as pg
import numpy as np
from typing import Callable

filename = "sprite.dat"

# Le nombre de frames a été choisi à 4 car le Sanyo PCH 25 en mode 4 contient 4 pixels par octets (donc 4 couleurs)
# Donc pour avoir un décalage des sprites pixel par pixel, on est obligé d'avoir quatre fois un décalage d'un pixel
# pour une animation lisse.
NB_FRAMES = 4   # Nombre de frames par sprites
SPRITE_WIDTH=12 # En nombre de pixels
SPRITE_HEIGHT=16 # En nombre de pixels

BLACK = (  0,  0,  0)
RED   = (255,  0,  0)
BLUE  = (  0,  0,255)
GREEN = (  0,255,  0)
WHITE = (255,255,255)
CYAN  = (  0,255,255)
MAGENTA = (255,  0,255)
YELLOW= (255,255,  0)
ORANGE=(255,165,  0)
PURPLE=(128,  0,128)
LIGHT_GREEN=(144,238,144)
LIGHT_YELLOW=(255,255,127)
DARK_GREY=(63,63,63)
# Si on veut changer 
PALETTE = [BLACK, RED, BLUE, WHITE]
# Numéro de la première ligne basic générée (incrément de 10 ensuite)
BEG_LINE = 9000

class Button:
    """
    Un bouton avec un texte et une fonction à appeler lorsqu'il est cliqué.
    """
    def __init__(self, font, texte : str, rect : pg.Rect, color : tuple, background : tuple, on_click: Callable[[object], None], draw_border : bool = False):
        
        self.text = font.render(texte, False, color, background)
        self.surface = pg.Surface((max(rect.width,self.text.get_width()), max(rect.height,self.text.get_height())))
        pos = (self.surface.get_width()-self.text.get_width())//2,(self.surface.get_height()-self.text.get_height())//2
        self.surface.blit(self.text, pos)
        self.rect = rect
        self.on_click = on_click
        self.is_pointed = False
        self.is_clicked = False
        self.draw_border = draw_border

    def draw(self, screen : pg.Surface):
        screen.blit(self.surface, (self.rect.x, self.rect.y))
        if self.is_clicked :
            pg.draw.rect(screen, (0, 255, 0), self.rect, 1)
        elif self.is_pointed :
            pg.draw.rect(screen, (255, 0, 0), self.rect, 1)
        elif self.draw_border :
            pg.draw.rect(screen, WHITE, self.rect, 1)

    def handle_events(self, editor, events : list[pg.event.Event]):
        for event in events :
            if event.type == pg.MOUSEMOTION :
                mouse_pos = pg.mouse.get_pos()
                if self.rect.collidepoint(mouse_pos) :
                    self.is_pointed = True
                else :
                    self.is_pointed = False
                    self.is_clicked = False
            if event.type == pg.MOUSEBUTTONDOWN :
                mouse_pos = pg.mouse.get_pos()
                if self.rect.collidepoint(mouse_pos) :
                    self.is_clicked = True
            if event.type == pg.MOUSEBUTTONUP :
                mouse_pos = pg.mouse.get_pos()
                if self.rect.collidepoint(mouse_pos) :
                    self.is_clicked = False
            if self.is_clicked:
                self.on_click()

class MetaSprite:
    """
    Les données pour un sprite donné dans l'éditeur.
    """
    def __init__(self):
        self.sprites = np.zeros((NB_FRAMES,SPRITE_WIDTH, SPRITE_HEIGHT), dtype=np.byte)
        self.frame   = 0
        self.surface = [pg.Surface((4*SPRITE_WIDTH, 2*SPRITE_HEIGHT)) for i in range(4)]
        self.zoomed_grid_rect = pg.Rect(70,10,32*SPRITE_WIDTH,16*SPRITE_HEIGHT)
        self.zoomed_sprite = pg.transform.scale(self.surface[self.frame], (32*SPRITE_WIDTH, 16*SPRITE_HEIGHT))
    
    def update_surface(self):
        for i in range(NB_FRAMES):
            self.surface[i].fill((0,0,0))
            for y in range(SPRITE_HEIGHT):
                for x in range(SPRITE_WIDTH):
                    color = PALETTE[self.sprites[i][x,y]]
                    pg.draw.rect(self.surface[i], color, (4*x, 2*y, 4, 2))
        self.zoomed_sprite = pg.transform.scale(self.surface[self.frame], (32*SPRITE_WIDTH, 16*SPRITE_HEIGHT))        
    
    def set_point(self, index, pixel):
        self.sprites[self.frame][pixel[0],pixel[1]] = index
        pg.draw.rect(self.surface[self.frame], PALETTE[index], (4*pixel[0], 2*pixel[1], 4, 2))
        self.zoomed_sprite = pg.transform.scale(self.surface[self.frame], (32*SPRITE_WIDTH, 16*SPRITE_HEIGHT))
    
    def grid_display(self, screen):
        screen.blit(self.zoomed_sprite, (70,10))
        pg.draw.rect(screen, WHITE, self.zoomed_grid_rect, 3)
        for i in range(32,32*SPRITE_WIDTH,32):
            pg.draw.line(screen, WHITE, (i+70,10), (i+70,16*SPRITE_HEIGHT+10), 1)
        for i in range(16, 16*SPRITE_HEIGHT, 16):
            pg.draw.line(screen, WHITE, (70,i+10), (32*SPRITE_WIDTH+70,i+10), 1)
    
    def sprite_display(self,screen):
        y = 400
        for s in self.surface:
            screen.blit(s, (800, y))
            y += 40
        
    def display_current_frame(self, screen):
        screen.blit(self.surface[self.frame], (150, 400))
        
    def next_frame(self):
        if self.frame < NB_FRAMES-1:
            self.frame += 1
        else:
            self.frame = 0
        self.zoomed_sprite = pg.transform.scale(self.surface[self.frame], (32*SPRITE_WIDTH, 16*SPRITE_HEIGHT))
            
    def previous_frame(self):
        if self.frame > 0:
            self.frame -= 1
        else:
            self.frame = NB_FRAMES-1
        self.zoomed_sprite = pg.transform.scale(self.surface[self.frame], (32*SPRITE_WIDTH, 16*SPRITE_HEIGHT))
    
    def generate_frames(self):
        for i in range(1,NB_FRAMES):
            self.sprites[i] = np.roll(self.sprites[i-1], shift=1, axis=0)
        self.update_surface()
        
    def generate_data(self, line : int):
        s = ""
        for f in range(NB_FRAMES):
            s += f"{line} DATA "
            for iy in range(SPRITE_HEIGHT):
                for ix in range(0,SPRITE_WIDTH,4):
                    value = self.sprites[f][ix+3,iy] + 4*self.sprites[f][ix+2,iy] + 16*self.sprites[f][ix+1,iy]
                    value += 64*self.sprites[f][ix+0,iy]
                    s += f"{value}" + ("," if ix < SPRITE_WIDTH-4 else "")
                s += "," if iy < SPRITE_HEIGHT-1 else ""
            s += "\n"
            line += 10
        return s,line
        
class EditorSprite:
    def __init__(self):
        pg.font.init()
        
        self.font = pg.font.SysFont("monospace", 24)
        self.sprites = []
        self.current_sprite = -1
        self.num_frame = 0
        self.counter_frame = -1
        self.max_counter = 80
        self.index_current_color = 0
        self.buttons = []
        self.buttons.append(Button(self.font, " New sprite ", pg.Rect((800,10),(200,25)), GREEN, DARK_GREY, self.new_sprite))
        self.buttons.append(Button(self.font, "Gen. frames ", pg.Rect((800,40), (200,25)), CYAN, DARK_GREY, self.generage_frames))
        self.buttons.append(Button(self.font, "Load sprites", pg.Rect((800,70), (200,25)), BLUE, DARK_GREY, self.load_sprite))
        self.buttons.append(Button(self.font, "Save sprites", pg.Rect((800,100), (200,25)), YELLOW, DARK_GREY, self.save_sprites))
        self.buttons.append(Button(self.font, "  Gen. Data ", pg.Rect((800,130), (200,25)), GREEN, DARK_GREY, self.generate_data))
        self.buttons.append(Button(self.font, "   ", pg.Rect((10,10),(50,25)), WHITE, BLACK, self.choose_black, True))
        self.buttons.append(Button(self.font, "   ", pg.Rect((10,40),(50,25)), WHITE, RED, self.choose_red, True))
        self.buttons.append(Button(self.font, "   ", pg.Rect((10,70),(50,25)), WHITE, BLUE, self.choose_blue, True))
        self.buttons.append(Button(self.font, "   ", pg.Rect((10,100),(50,25)), WHITE, WHITE, self.choose_white, True))

        self.buttons.append(Button(self.font, "→", pg.Rect((600, 610),(25,25)), WHITE, BLACK, self.next_sprite))
        self.buttons.append(Button(self.font, "←", pg.Rect((100, 610),(25,25)), WHITE, BLACK, self.prev_sprite))
        self.buttons.append(Button(self.font, "▶", pg.Rect((400, 610),(25,25)), GREEN, BLACK, self.play_animation))
        self.buttons.append(Button(self.font, "⏹", pg.Rect((300, 610),(25,25)), RED, BLACK, self.stop_animation))
        self.buttons.append(Button(self.font, "▲", pg.Rect((130,610),(25,25)), CYAN, BLACK, self.next_frame))
        self.buttons.append(Button(self.font, "▼", pg.Rect((180,610),(25,25)), MAGENTA, BLACK, self.prev_frame))

    def new_sprite(self):
        self.sprites.append(MetaSprite())
        self.current_sprite = len(self.sprites)-1
        print("New sprite created")
        
    def next_sprite(self):
        if self.current_sprite < len(self.sprites)-1:
            self.current_sprite += 1
        else:
            self.current_sprite = 0
            
    def prev_sprite(self):
        if self.current_sprite > 0:
            self.current_sprite -= 1
        else:
            self.current_sprite = len(self.sprites)-1
            
    def next_frame(self):
        self.sprites[self.current_sprite].next_frame()
            
    def prev_frame(self):
        self.sprites[self.current_sprite].previous_frame()
        
    def load_sprite(self):
        with open(filename, 'rb') as f:
            l = int.from_bytes(f.read(8), signed=False)
            for i in range(l):
                s = MetaSprite()
                s.sprites = np.load(f)
                s.update_surface()
                self.sprites.append(s)
        self.current_sprite = 0
    
    def save_sprites(self):
        with open(filename, 'wb') as f:
            f.write((len(self.sprites)).to_bytes(8,signed=False))
            for sprite in self.sprites:
                np.save(f, sprite.sprites)
        
    def generage_frames(self):
        self.sprites[self.current_sprite].generate_frames()

    def generate_data(self):
        line = BEG_LINE
        with open("sprites.bas", "w") as f:
            for sprite in self.sprites:
                bas, line = sprite.generate_data(line)
                f.write(bas)
    
    def play_animation(self):
        self.counter_frame = self.max_counter
    
    def stop_animation(self):
        self.counter_frame = -1
    
    def choose_black(self):
        self.index_current_color = 0

    def choose_red(self):
        self.index_current_color = 1

    def choose_blue(self):
        self.index_current_color = 2
        
    def choose_white(self):
        self.index_current_color  = 3

    def display_screen(self, screen : pg.Surface):
        """
        Affiche l'écran de l'éditeur.
        """
        screen.fill(BLACK)
        for b in self.buttons:
           b.draw(screen)
           
        if self.current_sprite >= 0:
            self.sprites[self.current_sprite].grid_display(screen)
            self.sprites[self.current_sprite].sprite_display(screen)
            self.sprites[self.current_sprite].display_current_frame(screen)
            if self.counter_frame != -1:
                self.counter_frame -= 1
                if self.counter_frame == 0:
                    self.sprites[self.current_sprite].next_frame()
                    self.counter_frame = self.max_counter

    def handle_events(self, events : list[pg.event.Event]):
        for b in self.buttons:
            b.handle_events(self, events)
        if self.current_sprite >= 0:
            for event in events:
                if event.type == pg.MOUSEBUTTONDOWN :
                    mouse_pos = pg.mouse.get_pos()
                    x = (mouse_pos[0]-70)//32
                    y = (mouse_pos[1]-10)//16
                    if self.sprites[self.current_sprite].zoomed_grid_rect.collidepoint(mouse_pos) :
                        self.sprites[self.current_sprite].set_point(self.index_current_color, (x,y))


pg.init()
screen = pg.display.set_mode((1200, 1024))
editor = EditorSprite()
running = True
while running:
    #editor.handle_events()
    editor.display_screen(screen)
    pg.display.flip()
    events = pg.event.get()
    editor.handle_events(events)
    for event in events:
        if event.type == pg.QUIT:
            running = False
pg.quit()
