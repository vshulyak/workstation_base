Workstation Base
================
[![CircleCI](https://circleci.com/gh/vshulyak/workstation_base/tree/master.svg?style=svg)](https://circleci.com/gh/vshulyak/workstation_base/tree/master)
[![](https://images.microbadger.com/badges/image/vshulyak/workstation_base.svg)](https://microbadger.com/images/vshulyak/workstation_base "Get your own image badge on microbadger.com")


This is a base image for my Data Science workstation for both localhost and remote deployment.

The image is not meant to be used as is by anyone but me. There are lots of packages you won't need. However, it's
possible to customize it easily just by forking.


The image includes
------------------

* CUDA/CUDNN for DL on GPU
* Miniconda 3 basic setup
* Java (I need it for Spark/Scala in derived images)
* NodeJS for JupyterLab extensions
* Goofys to mount data and notebook directories from S3/GCP
