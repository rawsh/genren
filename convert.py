import torch
import json
from binvox_rw import read_as_3d_array
from skimage.measure import marching_cubes
from sklearn.preprocessing import normalize
import numpy as np
import shutil
import os
import sys

sys.path.append("/home/robert/Documents/genren")

from meshutils import sample_triangle_mesh_with_normals

MAX_CAMERA_DISTANCE = 1.75

# for each model in the folder:
# data_dir = "./datasets/ShapeNet_Selected/Chair/"
data_dir = "./ShapeNet_Selected/Chair/"

# output folders
model_dir = "./chair_models_train"
image_dir = "./chair_images_train"
model_test_dir = "./chair_models_test"
image_test_dir = "./chair_images_test"

# rm existing files
if os.path.exists(model_dir):
    shutil.rmtree(model_dir)

if os.path.exists(image_dir):
    shutil.rmtree(image_dir)

if os.path.exists(model_test_dir):
    shutil.rmtree(model_test_dir)

if os.path.exists(image_test_dir):
    shutil.rmtree(image_test_dir)

# create new folders
os.makedirs(model_dir)
os.makedirs(image_dir)
os.makedirs(model_test_dir)
os.makedirs(image_test_dir)

def compute_camera_params_np(azimuth: float, elevation: float, distance: float):

    theta = np.deg2rad(azimuth)
    phi = np.deg2rad(elevation)

    camY = distance * np.sin(phi)
    temp = distance * np.cos(phi)
    camX = temp * np.cos(theta)
    camZ = temp * np.sin(theta)
    cam_pos = np.array([camX, camY, camZ])

    axisZ = cam_pos.copy()
    axisY = np.array([0, 1, 0])
    axisX = np.cross(axisY, axisZ)
    axisY = np.cross(axisZ, axisX)

    cam_mat = np.array([axisX, axisY, axisZ])
    l2 = np.atleast_1d(np.linalg.norm(cam_mat, 2, 1))
    l2[l2 == 0] = 1
    cam_mat = cam_mat / np.expand_dims(l2, 1)

    return torch.FloatTensor(cam_mat), torch.FloatTensor(cam_pos)

test_folder_names = ["1a6f615e8b1b5ae4dbbc9440457e303e", "1a8bbf2994788e2743e99e0cae970928", "1a74a83fa6d24b3cacd67ce2c72c02e"]

# for each file
rendering_data = dict()
test_rendering_data = dict()
Rs, Ts, voxel_RTs = [], [], []
for subdir, dirs, files in os.walk(data_dir):
    for dir in dirs:
        if dir == "rendering":
            prefix = subdir.split("/")[-1]
            img_output_folder = image_dir
            if prefix in test_folder_names:
                img_output_folder = image_test_dir

            for i in range(24):
                idx = str(i)
                if i < 10:
                    idx = "0" + idx

                shutil.copy(f'{subdir}/{dir}/{idx}.png', f'{img_output_folder}/{prefix}_{idx}.png')

            # Load the metadata file:
            metadata_file = f'{subdir}/{dir}/rendering_metadata.txt'
            m = open(metadata_file, "r")
            metadata_lines = m.readlines()
        
            # Get camera calibration.
            for i in range(len(metadata_lines)):
                idx = str(i)
                if i < 10:
                    idx = "0" + idx

                azim, elev, yaw, dist_ratio, fov = [
                    float(v) for v in metadata_lines[i].strip().split(" ")
                ]
                dist = dist_ratio * MAX_CAMERA_DISTANCE
                # Extrinsic matrix before transformation to PyTorch3D world space.
                # RT = compute_extrinsic_matrix(azim, elev, dist)
                # R, T = _compute_camera_calibration(RT)
                # Rs.append(R)
                # Ts.append(T)
                # voxel_RTs.append(RT)

                R, T = compute_camera_params_np(azim, elev, dist_ratio)
                if prefix in test_folder_names:
                    test_rendering_data[f"{prefix}_{idx}"] = dict()
                    test_rendering_data[f"{prefix}_{idx}"]["rotation"] = R.tolist()
                    test_rendering_data[f"{prefix}_{idx}"]["translation"] = T.tolist()
                else:
                    rendering_data[f"{prefix}_{idx}"] = dict()
                    rendering_data[f"{prefix}_{idx}"]["rotation"] = R.tolist()
                    rendering_data[f"{prefix}_{idx}"]["translation"] = T.tolist()

        else:
            model_output_folder = model_dir
            if dir in test_folder_names:
                model_output_folder = model_test_dir

            # Load the .binvox file:
            vox_file = f'{data_dir}{dir}/model.binvox'
            with open(vox_file, 'rb') as f:
                voxel = read_as_3d_array(f)

            # Convert the voxel representation to a point cloud:    
            vertices, faces, normals, _ = marching_cubes(voxel.data, 0.5)
            point_cloud = torch.from_numpy(vertices.astype(float))
            faces_tensor = torch.from_numpy(faces.astype(float))

            # points, normals = sample_triangle_mesh_with_normals(point_cloud, faces_tensor, 1000)

            # Compute the normals for the point cloud:
            # normals = torch.from_numpy(normalize(faces[:, :3], norm='l2'))

            # Save the point cloud and normals as PyTorch objects:
            output_file = dir
            torch.save(point_cloud, f'{model_output_folder}/{output_file}.PC.pt')
            torch.save(normals, f'{model_output_folder}/{output_file}.normals.pt')
    
# write metadata to file
with open(f'{image_dir}/rendering_metadata.json', 'w') as fp:
    json.dump(rendering_data, fp)

with open(f'{image_test_dir}/rendering_metadata.json', 'w') as fp:
    json.dump(test_rendering_data, fp)