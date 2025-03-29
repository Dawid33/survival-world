import numpy as np
import cv2
import subprocess
import random
import time
import os


def check_img(path, seed):
    # read image
    img = cv2.imread(path)
    original = img.copy()
    img = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    lower = np.array([50, 100, 50], dtype="uint8")
    upper = np.array([151, 128, 95], dtype="uint8")
    mask = cv2.inRange(img, lower, upper)

    contours, _ = cv2.findContours(mask, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    valid_contours = []

    original[512, 512] = [0, 0, 255]
    original = cv2.circle(original, (512, 512), 3, (0,0,255), -1)
    for c in contours:
        c = cv2.convexHull(c)
        if cv2.contourArea(c) > 6000:
            new_mask = np.zeros(mask.shape, np.uint8)
            cv2.drawContours(new_mask, [c], -1, 255, cv2.FILLED)
            mean = cv2.mean(mask, mask=new_mask)

            # cv2.imshow('new_mask', new_mask)
            # cv2.imshow('mask', mask)
            # cv2.imshow('img', original)
            # cv2.waitKey()
            # cv2.destroyAllWindows()
            cv2.drawContours(mask, [c], -1, (127, 200, 0), 2)
            cv2.drawContours(original, [c], -1, (127, 200, 0), 2)

            if mean[0] < 150 and mean[0] > 40:
                if cv2.pointPolygonTest(c, (512, 512), False) >= 0:
                    valid_contours.append(c)
                    

    if len(valid_contours) > 0:
        cv2.imwrite(f'filtered/{seed}.png', original)

def gen_maps(name):
    path = f'/media/dawids/561d79a1-4747-4079-a295-4f91627e286e/factorio_maps/{name}/'
    if not os.path.exists(path):
        os.makedirs(path)
    subprocess.call(["../../bin/x64/factorio", "--map-gen-settings", "map-gen-settings.json", "--generate-map-preview", path, "--generate-map-preview-random", "100", "--map-preview-scale", "1.2"])

    time.sleep(0.2)
    for filename in os.listdir(path):
        full_path = path + filename
        check_img(full_path, filename.split('.')[0])
    
subfolders = next(os.walk('/media/dawids/561d79a1-4747-4079-a295-4f91627e286e/factorio_maps/'))[1]
largest = 0
for f in subfolders:
    largest = max(largest, int(f))

while True:
    largest += 1;
    gen_maps(largest)

# while True:
#     # seed = x
#     # print("SEED: ", x)
#     seed = random.randrange(342, 18446744073709551613, 1)
#     subprocess.call(["../../bin/x64/factorio", "--map-gen-settings", "map-gen-settings.json", "--generate-map-preview", "test.png", "--map-gen-seed", f'{seed}', "--map-preview-scale", "1.2"])
#     time.sleep(0.5)
#     check_img(seed)
    
# seed = 3264598905
# subprocess.run(["../../bin/x64/factorio", "--map-gen-settings", "map-gen-settings.json", "--generate-map-preview", "test.png", "--map-gen-seed", f'{seed}']) 
# check_img(seed)


