import React, { useState, useEffect, Fragment } from "react";
import {
  Button,
  Header,
  Table,
  Divider,
  Breadcrumb,
  Modal,
  Icon,

  ButtonContent
} from "semantic-ui-react";
import _ from "lodash";
import moment from "moment";
import RenderValue from "../Shared/RenderValue";

import "../Styles/default";

import Breadcrumbs from "../Shared/Breadcrumb";
import MessageBox from "../Shared/MessageBox";
import axios from "axios";

export default function UnrejectTile(props) {
  const [selected, setSelected] = useState(null);
  const [open, setOpen] = React.useState(false);
  const flightDate = props.tile.flight_date;
  console.log(props);
  // console.log("UnrejectTile", props);

  const ignore_attributes = [
    "id",
    "geom",
    "usda_accepted_date",
    "rejected_date",
    "rejection_type",
    "county_id",
    "state_id",
    "utm_id",
    "tile_id",
    "rejection_report_date",
  ];

  const handleClick = (record) => {
    setSelected(record);
  };

  const handleSubmit = () => {
    if (flightDate === "null") {
      axios
        .post(`/unreject_tile/execute`, {
          poly_id: props.tile.poly_id,
          tile_id: props.tile.id,
          rejected_tile_id: selected.id,
          authenticity_token: props.token,
        })
        .then((response) => {
          console.log(response);
          window.location.href = "/unreject_tile";
        });
    } else {
      [];
    }
  };

  const submitModel = () => {
    axios
      .post(`/unreject_tile/execute`, {
        poly_id: props.tile.poly_id,
        tile_id: props.tile.id,
        rejected_tile_id: selected.id,
        authenticity_token: props.token,
      })
      .then((response) => {
        console.log(response);
        window.location.href = "/unreject_tile";
      });
  };
  return (
    <Fragment>
      <Breadcrumbs>
        <Breadcrumb.Section>Manage</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>
          <a href="./">Unreject Tile</a>
        </Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>{props.tile.poly_id}</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {renderList()}
      {renderSelected()}
      <br />
      <br />
    </Fragment>
  );

  function renderList() {
    if (selected) return null;
    return (
      <div className="table-overflow">
        <Table unstackable celled selectable>
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell>Poly ID</Table.HeaderCell>
              <Table.HeaderCell>Flight Date</Table.HeaderCell>
              <Table.HeaderCell>Rejected Date</Table.HeaderCell>
              <Table.HeaderCell>Rejection Reason</Table.HeaderCell>
              <Table.HeaderCell>Flown By</Table.HeaderCell>
            </Table.Row>
          </Table.Header>
          <Table.Body>
            {props.rejected_tiles.map((record, index) => {
              return (
                <Table.Row
                  onClick={() => handleClick(record)}
                  key={index}
                  style={{ cursor: "pointer" }}
                >
                  <Table.Cell>
                    <RenderValue value={record.poly_id} />
                  </Table.Cell>
                  <Table.Cell>
                    <RenderValue date={record.flight_date} />
                  </Table.Cell>
                  <Table.Cell>
                    <RenderValue date={record.rejected_date} />
                  </Table.Cell>
                  <Table.Cell>
                    <RenderValue value={record.rejection_type} />
                  </Table.Cell>
                  <Table.Cell>
                    <RenderValue value={record.flown_by_name} />
                  </Table.Cell>
                </Table.Row>
              );
            })}
          </Table.Body>
        </Table>
      </div>
    );
  }

  function renderSelected() {
    if (!selected) return null;
    return (
      <Fragment>
        <MessageBox message="Proceeding will overwrite the current tile (right table) with the attributes of the selected rejected tile (left column)." />
        <Divider />

        <div className="table-overflow">
          <Table unstackable definition celled>
            <Table.Header>
              <Table.Row>
                <Table.HeaderCell />
                <Table.HeaderCell>Selected Rejected Tile</Table.HeaderCell>
                <Table.HeaderCell>
                  Current Tile that will be overwritten
                </Table.HeaderCell>
              </Table.Row>
            </Table.Header>
            <Table.Body>
              <Table.Row>
                <Table.Cell collapsing textAlign="right">
                  ID
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={selected.id} />
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={props.tile.id} />
                </Table.Cell>
              </Table.Row>
              {Object.keys(selected).map((attribute, index) => {
                if (!ignore_attributes.includes(attribute)) {
                  return (
                    <Table.Row key={index}>
                      <Table.Cell collapsing textAlign="right">
                        <RenderValue value={_.startCase(attribute)} />
                      </Table.Cell>
                      <Table.Cell>
                        {attribute.toLowerCase().includes("_date") ? (
                          <RenderValue value={selected[attribute]} date />
                        ) : (
                          <RenderValue value={selected[attribute]} />
                        )}
                      </Table.Cell>
                      <Table.Cell
                        style={
                          props.tile[attribute] !== selected[attribute]
                            ? {
                                backgroundColor: "#cf0f0f",
                                fontWeight: "bold",
                              }
                            : { textDecoration: "none" }
                        }
                      >
                        <RenderValue
                          value={
                            props.tile.hasOwnProperty(attribute)
                              ? props.tile[attribute]
                              : "NA"
                          }
                        />
                      </Table.Cell>
                    </Table.Row>
                  );
                }
              })}
              <Table.Row>
                <Table.Cell collapsing textAlign="right">
                  Rejection Date
                </Table.Cell>
                <Table.Cell>
                  <RenderValue date={selected.rejected_date} />
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={props.rejected_date} />
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell collapsing textAlign="right">
                  Rejection Type
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={selected.rejection_type} />
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={props.rejection_type} />
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell collapsing textAlign="right">
                  Rejection Report Date
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={selected.rejection_report_date} date />
                </Table.Cell>
                <Table.Cell>
                  <RenderValue value={null} />
                </Table.Cell>
              </Table.Row>
            </Table.Body>
          </Table>
        </div>

        <Divider />
        <Modal
          closeIcon
          open={open}
          trigger={
            <Button primary animated floated="right" onClick={handleSubmit()}>
               <ButtonContent visible>Submit</ButtonContent>
          <ButtonContent hidden>
          <Icon name='arrow right' />
          </ButtonContent>
            </Button>
          }
          onClose={() => setOpen(false)}
          onOpen={() => {
            flightDate === "null" ? setOpen(false) : setOpen(true);
          }}
        >
          <Header icon="warning sign" content="Warning" />
          <Modal.Content>
            <p>
              The current Tile will be rejected before restoring this Rejected
              Tile.
            </p>
          </Modal.Content>
          <Modal.Actions>
            <Button animated secondary onClick={() => setOpen(false)}>
              <Button.Content visible>Cancel</Button.Content>
              <Button.Content hidden>
                <Icon name="remove" />
              </Button.Content>
            </Button>
            <Button
              animated
              primary
              onClick={() => {
                submitModel();
                setOpen(false);
              }}
            >
              <Button.Content visible>Submit</Button.Content>
              <Button.Content hidden>
                <Icon name="checkmark" />
              </Button.Content>
            </Button>
          </Modal.Actions>
        </Modal>
        <Button floated="right" animated secondary onClick={() => setSelected(null)}>
        <ButtonContent visible>Clear Selected</ButtonContent>
          <ButtonContent hidden>
          <Icon name="undo" />
          </ButtonContent>
        </Button>
        <div style={{ clear: "both" }} />
        <br />
        <br />
      </Fragment>
    );
  }
}
