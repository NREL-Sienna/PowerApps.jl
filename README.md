# PowerSystemsApps.jl

The `PowerSystemsApps.jl` package provides tools to view and manage systems created with
[PowerSystems.jl](https://github.com/NREL-SIIP/PowerSystems.jl)

## Usage

```
$ git clone https://github.com/NREL-SIIP/PowerSystemsApps.jl
$ cd PowerSystemsApps.jl
$ julia --project
julia> ]instantiate
```

### PowerSystemViewer

This application allows users to browse PowerSystems components and time series data in a web UI
via Plotly Dash. Here's how to start it:

```
$ julia --project src/system_explorer_app.jl
 Info: Listening on: 0.0.0.0:8050
```

Open your browser to the IP address and port listed. In this case: `http://0.0.0.0:8050`.

Next, enter a path to a raw data file or serialized JSON and load the system. Afterwards,
you can sort and filter component data.

Once you select one or more components you can select the `Components` tab and then plot
time series data.

## Developers

Consult https://dash.plotly.com/julia for help extending the UI.

Set the environment variable `SIIP_DEBUG` to enable hot-reloading of the UI.

Mac or Linux
```
$ export SIIP_DEBUG=1
# or
$ SIIP_DEBUG=1 julia --project src/system_explorer_app.jl
```

Windows PowerShell
```
$Env:SIIP_DEBUG = "1"
```

## License

PowerSystemsApps is released under a BSD [license](https://github.com/NREL/PowerSystemsApps.jl/blob/master/LICENSE).
PowerSystemsApps has been developed as part of the Scalable Integrated Infrastructure Planning (SIIP)
initiative at the U.S. Department of Energy's National Renewable Energy Laboratory ([NREL](https://www.nrel.gov/)).
