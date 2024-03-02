import React, { useState, useEffect } from "react";
import { Segment, Table, Header, Divider } from "semantic-ui-react";
import axios from "axios";
import {
  MapContainer,
  TileLayer,
  Polygon,
  Popup,
  LayerGroup,
  Circle,
} from "react-leaflet";
import "leaflet/dist/leaflet.css";
import RenderValue from "../../Shared/RenderValue";
import MessageBox from "../../Shared/MessageBox";

const TileStatusMap = ({ poly_id, token }) => {
  const [loaded, setLoaded] = useState(false);
  const [message, setMessage] = useState(false);
  const [center, setCenter] = useState([0, 0]);
  const [easement, setEasement] = useState(null);
  const [tile, setTile] = useState(null);
  const [footprints, setFootprints] = useState(null);
  const [frameCenters, setFrameCenters] = useState(null);
  const [photoIndices, setPhotoIndices] = useState(null);

  console.log("TileStatusMap", {
    poly_id,
    center,
    easement,
    tile,
    footprints,
    frameCenters,
    photoIndices,
  });

  useEffect(() => {
    axios
      .post(`/map/${poly_id}.geojson`, {
        authenticity_token: token,
      })
      .then(({ data }) => {
        // setData(response.data);
        // console.log(data);
        if (data.state) {
          setCenter(data.center);
          setEasement(data.easement);
          setTile(data.tile);
          setFootprints(data.footprints);
          setFrameCenters(data.frame_centers);
          setPhotoIndices(data.photo_indices);
          setTimeout(() => {
            setLoaded(true);
          }, 500);
        } else {
          setMessage({ status: "Error", title: "Error", text: data.message });
        }
      })
      .catch((error) => {
        console.error(error);
      });
  }, []);

  const flipCoordinates = (geometry) => {
    return geometry.coordinates[0].map((coordinates) => {
      if (Array.isArray(coordinates) && !Array.isArray(coordinates[0])) {
        return coordinates.reverse();
      }

      return coordinates.map((array) => {
        return array.reverse();
      });
    });
  };

  return (
    <Segment>
      {message && (
        <MessageBox
          status={"Error"}
          title={message.title}
          message={message.text}
        />
      )}
      {loaded && (
        <MapContainer
          center={center}
          zoom={13}
          style={{ height: "400px", zIndex: 1 }}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />

          {footprints && footprints.features.length > 0 && (
            <LayerGroup>
              {footprints.features.map((record, index) => {
                return (
                  <Polygon
                    key={index}
                    positions={flipCoordinates(record.geometry)}
                    pathOptions={{
                      fillColor: "#6b80f1",
                      weight: 1,
                      opacity: 1,
                      color: "white",
                      fillOpacity: 0.75,
                    }}
                    radius={75}
                  >
                    <Popup>
                      <Header as="h5">Footprint</Header>
                      <Table definition>
                        <Table.Row>
                          <Table.Cell>Strip Frame</Table.Cell>
                          <Table.Cell>
                            {record.properties.strip_frame}
                          </Table.Cell>
                        </Table.Row>
                        <Table.Row>
                          <Table.Cell>Flight Date</Table.Cell>
                          <Table.Cell>
                            <RenderValue
                              value={record.properties.flight_date}
                              date
                            />
                          </Table.Cell>
                        </Table.Row>
                      </Table>
                    </Popup>
                  </Polygon>
                );
              })}
            </LayerGroup>
          )}

          {tile && tile.features.length > 0 && (
            <LayerGroup>
              {tile.features.map((record, index) => {
                return (
                  <Polygon
                    key={index}
                    positions={flipCoordinates(record.geometry)}
                    pathOptions={{
                      fillColor: "gray",
                      weight: 1,
                      opacity: 1,
                      color: "white",
                      fillOpacity: 0.75,
                    }}
                    radius={75}
                  >
                    <Popup>
                      <Header as="h5">Tile</Header>
                      <Table definition>
                        <Table.Row>
                          <Table.Cell>Poly ID</Table.Cell>
                          <Table.Cell>{record.properties.poly_id}</Table.Cell>
                        </Table.Row>
                        <Table.Row>
                          <Table.Cell>Flight Date</Table.Cell>
                          <Table.Cell>
                            <RenderValue
                              value={record.properties.flight_date}
                              date
                            />
                          </Table.Cell>
                        </Table.Row>
                      </Table>
                    </Popup>
                  </Polygon>
                );
              })}
            </LayerGroup>
          )}

          {easement && easement.features.length > 0 && (
            <LayerGroup>
              {easement.features.map((record, index) => {
                return (
                  <Polygon
                    key={index}
                    positions={flipCoordinates(record.geometry)}
                    pathOptions={{
                      fillColor: "orange",
                      weight: 1,
                      opacity: 1,
                      color: "white",
                      fillOpacity: 1,
                    }}
                    radius={75}
                  >
                    <Popup>
                      <Header as="h5">Easement</Header>
                      <Table definition>
                        <Table.Row>
                          <Table.Cell>Poly ID</Table.Cell>
                          <Table.Cell>{record.properties.poly_id}</Table.Cell>
                        </Table.Row>
                        <Table.Row>
                          <Table.Cell>Flight Date</Table.Cell>
                          <Table.Cell>
                            <RenderValue
                              value={record.properties.flight_date}
                              date
                            />
                          </Table.Cell>
                        </Table.Row>
                      </Table>
                    </Popup>
                  </Polygon>
                );
              })}
            </LayerGroup>
          )}

          {photoIndices && photoIndices.features.length > 0 && (
            <LayerGroup>
              {photoIndices.features.map((record, index) => {
                console.warn(record, index);
                return (
                  <Circle
                    key={index}
                    center={record.geometry.coordinates.reverse()}
                    pathOptions={{
                      color: "white",
                      fillColor: "white",
                      fillOpacity: 1,
                    }}
                    radius={75}
                  >
                    <Popup>
                      <Header as="h5">Photo Index</Header>
                      <Table definition>
                        <Table.Row>
                          <Table.Cell>Strip Frame</Table.Cell>
                          <Table.Cell>
                            {record.properties.strip_frame}
                          </Table.Cell>
                        </Table.Row>
                        <Table.Row>
                          <Table.Cell>Flight Date</Table.Cell>
                          <Table.Cell>
                            <RenderValue
                              value={record.properties.flight_date}
                              utc
                            />
                          </Table.Cell>
                        </Table.Row>
                      </Table>
                    </Popup>
                  </Circle>
                );
              })}
            </LayerGroup>
          )}

          {frameCenters && frameCenters.features.length > 0 && (
            <LayerGroup>
              {frameCenters.features.map((record, index) => {
                console.warn(record, index);
                return (
                  <Circle
                    key={index}
                    center={record.geometry.coordinates.reverse()}
                    pathOptions={{
                      color: "green",
                      fillColor: "green",
                      fillOpacity: 1,
                    }}
                    radius={75}
                  >
                    <Popup>
                      <Header as="h5">Frame Center</Header>
                      <Table definition>
                        <Table.Row>
                          <Table.Cell>Strip Frame</Table.Cell>
                          <Table.Cell>
                            {record.properties.strip_frame}
                          </Table.Cell>
                        </Table.Row>
                        <Table.Row>
                          <Table.Cell>Flight Date</Table.Cell>
                          <Table.Cell>
                            <RenderValue
                              value={record.properties.flight_date}
                              utc
                            />
                          </Table.Cell>
                        </Table.Row>
                      </Table>
                    </Popup>
                  </Circle>
                );
              })}
            </LayerGroup>
          )}
        </MapContainer>
      )}
    </Segment>
  );
};

export default TileStatusMap;
50;
