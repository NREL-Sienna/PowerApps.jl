# PowerSystemManager.jl

The `PowerSystemManager.jl` package provides tools to view and manage systems created with
[PowerSystems.jl](https://github.com/NREL-SIIP/PowerSystems.jl)

## Usage

```
$ git clone https://github.com/NREL-SIIP/PowerSystemManager.jl
$ cd PowerSystemManager.jl
$ julia --project
julia> ]instantiate
```

### PowerSystemViewer

This application allows users to browse PowerSystems components and time series data in a web UI
via Plotly Dash. Here's how to start it:

```
$ julia src/app.jl
 Info: Listening on: 0.0.0.0:8050
```

Open your browser to the IP address and port listed. In this case: `http:0.0.0.0:8050`.

Next, enter a path to a raw data file or serialized JSON and load the system. Afterwards,
you can sort and filter component data.

## Developers

Consult https://dash.plotly.com/julia for help extending the UI.

Change the `run_server` call in `src/app.jl` to enable hot-reloading of the UI.

```
run_server(app, "0.0.0.0", debug = true, dev_tools_hot_reload = true)
```

## License

PowerSystemManager is released under a BSD [license](https://github.com/NREL/PowerSystemManager.jl/blob/master/LICENSE).
PowerSystemManager has been developed as part of the Scalable Integrated Infrastructure Planning (SIIP)
initiative at the U.S. Department of Energy's National Renewable Energy Laboratory ([NREL](https://www.nrel.gov/)).
