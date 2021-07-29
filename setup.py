import setuptools 

setuptools.setup(
    name = "SurfTexture",
    version = "0.0.1", 
    author = "Jason Kai", 
    author_email = "tkai@uwo.ca",
    packages = setuptools.find_packages(),
    include_package_data = True, 
    python_requires = "~=3.7",
    install_requires = [ 
        "snakebids~=0.3.10",
    ]
)