import os
import sys

print("Python executable:", sys.executable)
print("Current working directory:", os.getcwd())
print("Directory contents:")
for item in os.listdir('.'):
    print(f"  {item}")

if os.path.exists('backend'):
    print("\nBackend directory found!")
    print("Backend contents:")
    for item in os.listdir('backend'):
        print(f"  backend/{item}")
    
    if os.path.exists('backend/src'):
        print("\nSrc directory found!")
        print("Src contents:")
        for item in os.listdir('backend/src'):
            print(f"  backend/src/{item}")
else:
    print("\nBackend directory NOT found!")
