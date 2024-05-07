from setuptools import setup, find_packages

setup(
    name='segfreetk',
    version='0.1.0a1',
    packages=find_packages(exclude=["tests"]),
    license='Apache License 2.0',
    author='Javier Iranzo-Sanchez',
    description='A toolkit for Segmentation-Free Streaming Translation',
    install_requires=[
        "fairseq==0.10.2",
        "torch==1.7.0",
        "numpy",
        "scipy",
        "sentencepiece",
        'segmenter @ git+https://mllp.upv.es/git/jiranzo/ST-Segmenter.git@develop'
    ]
)
